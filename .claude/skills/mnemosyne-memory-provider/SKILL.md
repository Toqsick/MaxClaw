---
name: mnemosyne-memory-provider
description: Mnemosyne native memory provider for Hermes Agent — embedding engine setup (fastembed), DB schema, vector search,
  consolidation workflow, and troubleshooting. Use when Hermes memory provider is set to 'mnemosyne' and embeddings are missing,
  recall is degraded, or the user asks about memory/embedding status.
version: 1.2.0
author: Yuno (the user's assistant)
platforms:
- linux
- macos
tags:
- hermes
- memory
- mnemosyne
- embeddings
- fastembed
- sqlite
- vector-search
lane: worker-heavy
reasoning_effort: xhigh
---
# Mnemosyne Memory Provider

Hermes Agent's native local memory backend (`provider: mnemosyne` in config.yaml). Covers embedding generation, vector search setup, consolidation, and troubleshooting.

## Quick Reference

| Task | Command |
|------|---------|
| Check status | `mnemosyne_stats` |
| Consolidate | `mnemosyne_sleep(all_sessions=True)` |
| Recall | `mnemosyne_recall(query, top_k=5)` |
| DB path | `~/.hermes/mnemosyne/data/mnemosyne.db` |
| Config | `~/.hermes/config.yaml` → `provider: mnemosyne` |

## Architecture

```
~/.hermes/mnemosyne/
├── data/
│   ├── mnemosyne.db          # Haupt-DB (working_memory, episodic_memory, facts, memory_embeddings)
│   ├── mnemosyne.db-wal      # WAL journal
│   └── triples.db            # Knowledge Graph
└── mnemosyne.db              # Symlink oder Backup

~/.hermes/config.yaml
└── provider: mnemosyne
    user_char_limit: 4094
    user_profile_enabled: true
    write_approval: true/false
```

### Key Tables

| Table | Purpose |
|-------|---------|
| `working_memory` | Rohe Session-Memories (659 Einträge) |
| `episodic_memory` | Konsolidierte Zusammenfassungen (100 Einträge) |
| `facts` | Extrakte Fakten (29 Einträge) |
| `memory_embeddings` | Vektor-Speicher (bge-small-en-v1.5, 384 dim) |
| `vec_episodes` | ANN-Vektor-Index (vec0 Extension, int8[384]) |
| `vec_facts` | ANN-Vektor-Index für Facts |
| `fts_working` | Full-Text Search Index |
| `fts_episodes` | Full-Text Search Index |
| `memoria_facts` | Strukturierte Fakten (267) |
| `memoria_instructions` | Instruktionen (71) |
| `memoria_preferences` | Präferenzen (10) |

## Embedding Engine Setup

### Problem: `available: False`

Mnemosyne's Embedding Engine requires `fastembed` for local embeddings. Without it, no embeddings are generated and `mnemosyne_recall` falls back to FTS5 only.

### Fix: Install fastembed

```bash
uv pip install fastembed --python ~/.hermes/hermes-agent/venv/bin/python
```

After install, verify:
```python
from mnemosyne.core import embeddings
assert embeddings.available() == True
```

### Generate Missing Embeddings

When `memory_embeddings` has gaps (e.g., 127/659 working memories have embeddings):

```python
import sqlite3, json, numpy as np
from fastembed import TextEmbedding

embedder = TextEmbedding('BAAI/bge-small-en-v1.5')

class NpEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, (np.floating,)):
            return round(float(obj), 6)
        return super().default(obj)

db = sqlite3.connect('~/.hermes/mnemosyne/data/mnemosyne.db')
cur = db.cursor()

# Find working_memory rows without embeddings
cur.execute("""
    SELECT wm.id, wm.content 
    FROM working_memory wm
    LEFT JOIN memory_embeddings me ON wm.id = me.memory_id
    WHERE me.memory_id IS NULL AND wm.content IS NOT NULL
""")

for mem_id, content in cur.fetchall():
    vec = list(embedder.embed(content[:500]))[0]
    vec_json = json.dumps(vec.tolist(), cls=NpEncoder)
    cur.execute(
        "INSERT OR REPLACE INTO memory_embeddings (memory_id, embedding_json, model) VALUES (?, ?, ?)",
        (mem_id, vec_json, 'BAAI/bge-small-en-v1.5')
    )

db.commit()
```

**⚠️ Pitfall:** `numpy.float32` is not JSON-serializable. Always use `json.dumps(vec.tolist(), cls=NpEncoder)` or convert to Python floats manually.

**Performance:** ~70 embeddings/second. 659 memories take ~10 seconds.

## Vector Search (vec0 Extension)

### Setup

The `vec0` virtual tables require the sqlite-vec extension. It may exist in the uv cache but not be loadable directly:

```python
import sqlite3
db = sqlite3.connect('~/.hermes/mnemosyne/data/mnemosyne.db')
db.enable_load_extension(True)
db.load_extension('~/.cache/uv/archive-v0/KPdxUjNCRk5M-gly/sqlite_vec/vec0.so')
```

### vec0 Schema

```sql
CREATE VIRTUAL TABLE vec_episodes USING vec0(embedding int8[384]);
```

**⚠️ vec0 requires `int8` quantized vectors, not float32.** The `memory_embeddings` table stores JSON float arrays for portability. The `vec_*` tables are optional ANN indices for performance.

### Current State After Fix

| Metric | Before | After |
|--------|--------|-------|
| `memory_embeddings` total | 127 | 886 |
| Working with embedding | 0 | 659 |
| Episodic with embedding | 0 | 100 |
| `embeddings.available()` | False | True |
| `mnemosyne_stats.vectors` | 0 | 100 |

## Consolidation Workflow

### What It Does

`mnemosyne_sleep` consolidates unconsolidated working memories into episodic summaries:
- Groups related working memories
- Creates `episodic_memory` entries (summaries)
- Updates `memory_embeddings` for new summaries
- Tracks consolidation in `consolidation_log`

### Run Consolidation

```python
from hermes_tools import mnemosyne_sleep
result = mnemosyne_sleep(all_sessions=True)
# Returns: {"status": "consolidated", "items_consolidated": N, "summaries_created": M}
```

### Stats After Consolidation

```python
from hermes_tools import mnemosyne_stats
stats = mnemosyne_stats()
# working.consolidated: 609/660
# episodic.total: 100
# episodic.vectors: 100
```

## Troubleshooting

### `vectors: 0` in stats

**Cause:** `fastembed` not installed or `available()` returns False.
**Fix:** Install fastembed (see above), then regenerate embeddings.

### Mnemosyne API: trust_tier statt veracity

Die Mnemosyne `remember()`-API nutzt **`trust_tier`**, NICHT `veracity`. Das `hermes_tools.mnemosyne_remember()`-Interface hat andere Parameter.

**Korrekte Parameter für `mnemosyne.remember()` (direct import):**
```
content: str, source: str = 'conversation', importance: float = 0.5,
metadata: Dict = None, scope: str = 'session', valid_until: str = None,
extract_entities: bool = False, extract: bool = False,
bank: str = None, trust_tier: str = None
```

**Korrekte Parameter für `mnemosyne.recall()` (direct import):**
```
query: str, top_k: int = 5, *, from_date, to_date, source, topic,
temporal_weight, vec_weight, fts_weight, importance_weight, bank
```

### API Auto-Detection Pattern

Der `hermes-orchestration` Skill verwendet `inspect.signature()` um automatisch zwischen `mnemosyne.remember()` (top_k), `hermes_tools.mnemosyne_remember()` (limit), und Plugin-Varianten zu unterscheiden:

```python
import inspect
params = inspect.signature(remember_fn).parameters
kwargs = {"top_k": 3} if "top_k" in params else {"limit": 3}
results = remember_fn(query=query, **kwargs)
```

Immer drei Fallback-Stufen probieren: (1) `mnemosyne_hermes` → (2) `hermes_tools` → (3) direktes `mnemosyne`.

**Cause:** Direct `json.dumps()` on numpy arrays.
**Fix:** Use custom `NpEncoder` or `vec.tolist()` with float conversion.

### `no such module: vec0`

**Cause:** sqlite-vec extension not found or not loaded.
**Fix:** Load from uv cache path explicitly (see Vector Search section).

### `database is locked`

**Cause:** Multiple processes accessing the DB (e.g., Hermes agent + manual script).
**Fix:** Close other processes or use WAL mode (already enabled).

### Embeddings exist but recall doesn't use them

**Cause:** `mnemosyne_recall` needs `vec_weight` parameter to use vector search.
**Fix:** Call `mnemosyne_recall(query, vec_weight=0.5, fts_weight=0.5)` for hybrid search.

### `TypeError: unexpected keyword argument 'veracity'` / `'limit'`

**Cause:** Three different import paths exist (`mnemosyne`, `hermes_tools`,
`mnemosyne_hermes`) and each has a **different signature**:
- Direct `mnemosyne.remember` uses `trust_tier`, not `veracity`
- Direct `mnemosyne.recall` uses `top_k`, not `limit`
- `hermes_tools.mnemosyne_*` wrappers use `veracity` / `limit`

**Fix:** Auto-detect kwargs via `inspect.signature()` before calling. Full
pattern with auto-detection helpers: see `references/api-signature.md`.

### Stable content-hash for dedup trackers

`hash(content)` returns a different value on every Python run
(`PYTHONHASHSEED` randomization). Using it as a dedup ID means cron jobs
re-import the same content every time.

**Fix:** Use `hashlib.md5(content.encode("utf-8")).hexdigest()[:16]`.

## See Also

- `hermes-agent` skill: Memory provider configuration
- `system-documentation` skill: System state documentation
- Mnemosyne source: `~/.hermes/hermes-agent/venv/lib/python3.11/site-packages/mnemosyne/`
- `references/api-signature.md` — Full signature differences, auto-detect helpers, kwarg-name table

```yaml
# ~/.hermes/config.yaml
provider: mnemosyne
user_char_limit: 4094
user_profile_enabled: true
write_approval: true  # Set to false for auto-write without confirmation
```

**Note:** `write_approval: true` requires user confirmation for every memory write via the `memory` tool. Set to `false` for normal operation.

## Memory Hygiene: Was NICHT in Mnemosyne speichern (2026-06-30)

Mnemosyne hat `write_approval: false` als Default für normale Sessions. Trotzdem landen manche Memory-Schreibe in der Working-Memory-Tabelle die dort nichts verloren haben. Die wichtigsten Anti-Patterns aus 2026-06-30:

### Background-Process-Quittungen NICHT speichern

**Schlecht:** `[IMPORTANT: Background process proc_X terminated normally (exit 0). Command: timeout 15 curl ... Output: ...bash: IOCTL...FIN]` als `[USER]`-Message → Mnemosyne persistiert das als Working-Memory Eintrag (importance 0.30). Nach 9 SSE-Test-Quittungen sind das 18 Memories (9 vom User + 9 von meinen Antwort-Memos), Recalls werden vom Lärm dominiert.

**Workaround:** Solche Quittungen gar nicht erst mit `mnemosyne_remember` bestätigen — schweigend quittieren (kurze Acknowledge im User-Facing Output, nicht in Memory persistieren). Wenn doch passiert, siehe Cleanup-Pattern unten.

**Wenn's schon passiert ist (Cleanup-Pattern):**
```python
# 1. Konsolidiert: 1 hoher-importance Memory, fasst die Episode zusammen
mnemosyne_remember(
    content="Session 2026-06-30 — N Background-Process-Quittungen mit Bash-IOCTL-Diagnose. Ursprüngliche proc-IDs: [list]. Lesson: System-Receipts sind ephemeral.",
    importance=0.4, source='insight', scope='session', veracity='tool'
)

# 2. Alle Quittungs-Originale + dazu gehörige Antwort-Memos chainen
for old_id in [list_of_proc_quittance_memory_ids]:
    mnemosyne_invalidate(memory_id=old_id, replacement_id='<neue_id>')

# 3. Eigene Antwort-Memos ("passt alles, Exit 0") ebenfalls invalidieren
```

### Auch nicht speichern

| Quitting-Type | Warum nicht | Stattdessen |
|---|---|---|
| `[IMPORTANT: Background process X completed]` | Ephemeraler Diagnose-Lärm | Schweigen oder 1-Satz-Ack im Output |
| "Alles ok, Sigterm sauber durchgegangen"-Bestätigungen | Repetitive noise | Nur persistieren wenn neue Erkenntnis |
| Memory-Probe-Logs aus AutoConsolidation | Internal state | Mnemosyne-Stats hat das schon |
| "Permission to commit granted" Receipts | User-Memo nicht nötig | git output gibt Antwort |

### Mnemosyne-API-Wahl: invalidate vs forget

- `mnemosyne_invalidate(memory_id, replacement_id=...)` — setzt `valid_until` + chain via `superseded_by`. Andere Memories die drauf verwiesen haben werden redirected. **Wenn** der Fakt noch bedingt relevant ist (z.B. "war falsch, neuer Fakt ist X").
- `mnemosyne_forget(memory_id)` — hard delete. **Wenn** der Fakt komplett unwichtig ist und keinen Replacement hat.

Default im Cleanup: `invalidate` mit `replacement_id` zur Konsolidierungs-Memory. So bleibt die Recall-Chain konsistent.

## § Bulk Working Memory Cleanup (2026-07-05)

**Wann:** Wenn `mnemosyne_stats` viele unconsolidated Working-Memory-Einträge zeigt (z. B. `working.unconsolidated >> 200`), Recalls von tiny-Conversation-Echos dominiert werden, oder du regelmäßige Memory-Hygiene-Cadence fährst (monatlich empfohlen).

### Architektur-Verständnis vorausgesetzt

Mnemosyne hat mehrere Speicherschichten — die wichtigsten für Cleanup:

| Tabelle | Zweck | Typische Größe |
|---------|-------|----------------|
| `working_memory` (BEAM) | Rohe Session-Memories via `mnemosyne_remember()` | 2.000+ Einträge |
| `episodic_memory` | Konsolidierte Zusammenfassungen via `mnemosyne_sleep` | 100-400 Einträge |
| `memoria_facts` | Strukturierte Fakten | 200-300 Einträge |
| `memoria_instructions` | Verhaltensanker | 50-300 Einträge |
| `memoria_preferences` | Benutzerpräferenzen | 10-50 Einträge |
| `consolidation_log` | Audit-Trail der Konsolidierung | ~250 Einträge |
| `memories` (SQLite root) | **Nicht** der Working-Memory! Nur ~4 Einträge typisch | ~4 |

**Wichtig:** Der `memories`-Table (den das `memory`-Tool anspricht) ist NICHT der Working-Memory. Die 2.000+ Einträge leben ausschließlich in der BEAM `working_memory`-Tabelle. `mnemosyne_stats().working.total` berichtet die BEAM-Zahlen, nicht den `memories`-Count. Bei erstem DB-Connect mit `sqlite3` siehst du nur 4 Memories — das ist KEIN Fehler.

### Der BEAM Unterschied: `valid_until` + `superseded_by`

Working-Memory in BEAM hat ein **soft-delete**-Schema statt harter Löschung:

```sql
SELECT id, importance, valid_until, superseded_by FROM working_memory LIMIT 5;
-- valid_until IS NULL → alive
-- valid_until IS NOT NULL → invalidated (soft-deleted, aus Recalls ausgeschlossen)
-- superseded_by = 'mnemosyne:cleanup:<Datum>:tiny-importance-bulk' → bulk-Token
```

**Vorteil:** Kein `DELETE`, kein VACUUM nötig. Vollständig reversibel per `UPDATE SET valid_until=NULL, superseded_by=NULL`.

**Nachteil:** DB-File-Größe ändert sich nicht (Zeilen bleiben). Der Vorteil ist: **Rollback ist immer möglich.**

### Drei-Schicht-Safety-Net

Jeder Bulk-Cleanup besteht aus **drei unabhängigen Sicherungen**:

| Layer | Was | Wo | Reversibilität |
|-------|-----|----|----------------|
| ① DB-Snapshot | `shutil.copy2` der mnemosyne.db | `~/50-System/backups/mnemosyne/mnemosyne-pre-cleanup-<Datum>.db` | Vollständige DB-Wiederherstellung |
| ② Backout-ID-Liste | JSON mit allen 2.000+ IDs + fertigem Rollback-SQL | `cleanup-<Datum>-backout-ids.json` | `UPDATE SET valid_until=NULL, superseded_by=NULL WHERE id IN (...)` |
| ③ Audit-Trail | `consolidation_log`-Eintrag mit Session-ID, Anzahl, Token | `consolidation_log.id = <n>` | Nachvollziehbarkeit |

### Schritt-für-Schritt-Procedure (Code)

Vollständiger, kopierbarer Code pro Schritt — siehe `references/beam-working-cleanup.md`. Die SKILL.md enthält hier die Kurzform:

1. **Snapshot + Kandidaten-IDs exportieren** → `shutil.copy2` der DB + SQL-Query: `SELECT id, importance, content FROM working_memory WHERE valid_until IS NULL AND importance < 0.5 ORDER BY importance ASC` + JSON-Backout-Datei mit Rollback-SQL
2. **Transaktionale Invalidierung** → `BEGIN IMMEDIATE`, 1x Audit in `consolidation_log`, UPDATE in Chunks à 500 IDs, `COMMIT`. **Pitfalls:** `BEGIN IMMEDIATE` statt DEFERRED (WAL-Deadlock), Chunks à 500 IDs, `WHERE importance < 0.5` im UPDATE wiederholen
3. **Verifikation** → `PRAGMA integrity_check`, `mn.beam.get_working_stats()`, Recall-Test, Importance-Verteilung alive vs invalidated
4. **Sleep-Pass** → `mn.beam.sleep(dry_run=False)` → erwartet `no_op` (Memories < 24h alt)

### Nach Cleanup — Sleep-Pass

```python
result = mn.beam.sleep(dry_run=False)
# → {"status": "no_op", "message": "No old working memories to consolidate"}
```

zwischenzeitlich erstellt wurden.

**Zusätzlich: Immer `AND valid_until IS NULL` anfügen.** Der erste Bulk-Cleanup (2026-07-05) hatte diesen Filter nicht — was dazu führte, dass der Cron-Lauf bereits invalidierte IDs erneut einsammelte und einen Count-Mismatch verursachte. Fix: `valid_until IS NULL` in **beide** Queries — den SELECT-Sammler **und** den UPDATE-Invalidator.

### Aggressivere Varianten (nur nach User-Abgleich)

| Variante | Erklärung | Risiko |
|----------|-----------|--------|
| Mid+ Low purge | `importance < 0.7` statt 0.5 | Entfernt auch mid-quality Memories — nur tun wenn Recall aus Episodic+Memoria lebt |
| Full BEAM reset | `DELETE FROM working_memory WHERE valid_until IS NOT NULL` | Physische Löschung — **macht Rollback unmöglich** |
| VACUUM | `VACUUM;` nach DELETE | Schrumpft DB-File — Daten physikalisch weg |

### Wartungs-Cadence

| Intervall | Aktion | Aufwand |
|-----------|--------|---------|
| Monatlich | Tiny-Purge-Pass (< 0.5 → invalidate) | 5 Min |
| Quartalsweise | Mid-Audit (≥ 0.5 < 0.7), ggf. purgen | 20 Min |
| Halbjährlich | Memoria-Instructions + Preferences review | 1 h |

### Anti-Pattern: Identische Memories aus verschiedenen Sessions

Wenn `mnemosyne_remember` bei jedem Session-Start mit denselben Fakten aufgerufen wird (gleicher Inhalt + gleiche importance), entstehen mehrere identische Einträge in `working_memory`. Mnemosyne dedupliziert NICHT automatisch.

**Fix:** Hash-basierte Dedup:
```python
import hashlib
content_hash = hashlib.md5(content.encode("utf-8")).hexdigest()[:16]
# Vor mnemosyne_remember: prüfen ob content_hash schon in working_memory.content_hash existiert
```

## § Monatlicher Cron Cleanup (Script + Betriebshygiene)

### Architektur

Ein **selbstständiges Bash-Skript** (`scripts/mnemosyne-monthly-cleanup.sh`) das:

| Komponente | Beschreibung |
|---|---|
| 25-Tage-Sperre | `.last-mnemosyne-cleanup`-Datei mit Datum → verhindert Mehrfachausführungen pro Monat |
| Pre-Flight | DB existiert? sqlite3? venv? Sperre gültig? → alles vor erstem Schreibzugriff |
| Layer ① Snapshot | `cp` der DB → `~/50-System/backups/mnemosyne/mnemosyne-pre-cleanup-<Datum>.db` |
| Layer ② Backout | Python sammelt `importance < 0.5 AND valid_until IS NULL` → JSON mit fertigem Rollback-SQL |
| Layer ③ Audit | `BEGIN IMMEDIATE` → `consolidation_log`-Eintrag → Chunked UPDATE (500 IDs) → `COMMIT` |
| Telegram-Report | Lädt Credentials aus `~/.hermes/.env` (NIE im Crontab!) |
| Cron | `0 9 1 * *` → Log nach `~/logs/mnemosyne-monthly-cleanup.log` |

### Idempotenter UPDATE (defensiv, bug-frei getestet)

```sql
UPDATE working_memory
SET valid_until = ?, superseded_by = ?
WHERE id IN (?) AND importance < 0.5 AND valid_until IS NULL
```

Wenn ein Eintrag bereits invalidiert wurde (vorheriger Lauf, manuelle Aktion), wird er nicht erneut angetastet.

### Pitfalls aus erster Ausführung (2026-07-05)

| # | Problem | Symptom | Fix |
|---|---------|---------|-----|
| 1 | `.env`-Variable heisst `TELEGRAM_HOME_CHANNEL`, nicht `TELEGRAM_CHAT_ID` | Telegram-Report nie gesendet | Im Skript tatsächliche Variable aus `.env` verwenden, nicht raten |
| 2 | `WHERE importance < 0.5` ohne `valid_until IS NULL` | Sammelt bereits invalidierte IDs → Count-Mismatch | Immer `AND valid_until IS NULL` an SELECT **und** UPDATE |
| 3 | `BEGIN DEFERRED` statt `BEGIN IMMEDIATE` | WAL-Deadlock bei Hermes-TUI-Lesezugriff | Immer `BEGIN IMMEDIATE` bei Bulk-Schreibzugriffen |
| 4 | Credentials im Crontab hartcodiert | Secret-Leak in `crontab -l` | Niemals Credentials im Crontab; immer aus `.env` laden |

### Manuelle Ausführung

```bash
# Normal (überspringt wenn < 25 Tage seit letztem Lauf)
bash ~/50-System/bin/mnemosyne-monthly-cleanup.sh

# Force (Sperre zurücksetzen)
rm ~/50-System/backups/mnemosyne/.last-mnemosyne-cleanup
bash ~/50-System/bin/mnemosyne-monthly-cleanup.sh

# Logs
tail -f ~/logs/mnemosyne-monthly-cleanup.log
```

### Template-Wiederverwendung

Das Skript in `scripts/mnemosyne-monthly-cleanup.sh` ist als **Vorlage für andere DB-Hygiene-Crons** nutzbar. Anpassungspunkte:

1. `DB_PATH` → Ziel-DB
2. `IMPORTANCE_MAX` → Schwellwert (z. B. `0.7` für Mid-Cleanup)
3. SQL-Inline-Blöcke → andere WHERE-Bedingungen

### Siehe auch

- `scripts/mnemosyne-monthly-cleanup.sh` — ausführbares Template
- `references/beam-working-cleanup.md` — Bulk-Cleanup-Procedure mit Code
- `note-taking/obsidian` — Vault-Operationen (Notes anlegen, Wikilinks)

## § Obsidian-Vault-Sync (Memory-Hygiene-Begleitung)

the user's Betriebspraxis: **Mnemosyne ist Runtime-Memory, Obsidian ist das persistente menschliche Wissen.** Relevante Erkenntnisse aus Memory-Operationen gehören in beide Systeme — sie bedienen unterschiedliche Lese-Schnittstellen und schaffen gegenseitige Fehlerresilienz.

### Was synchronisieren

| Mnemosyne-Inhalt | Obsidian-Ziel | Timing |
|---|---|---|
| Cleanup-Reports (importance ≥ 0.85) | `07 Archiv/` | Nach jedem Bulk-Cleanup |
| Wartungs-SOPs (Scripts, Cron, Procedures) | `03 Projekte/` oder Skill-Verzeichnis | Einmalig nach Ersteinrichtung |
| Session-übergreifende Kontext-Fakten | `01 Kontext/` | Wenn Fakt stabil und referenzierbar ist |

### Was NICHT synchronisieren

- Working-Memory-Rohdaten (Einzelfakten aus einer Session)
- Temporäre Kontext-Notizen („gerade getestet")
- Low-importance Conversation-Echos (die ja gerade invalidiert wurden)

### Mnemosyne-Triple zur Auffindbarkeit

```python
mnemosyne_triple_add(
    subject="mn-hygiene-sync",
    predicate="dokumentiert-in",
    object="Obsidian Vault/07 Archiv/Mnemosyne Cleanup Report - 2026-07-05.md",
    valid_from="2026-07-05"
)
```

## See Also (cross-skill)

- `devops/hermes-maintenance` §13 "Memory-Hygiene: System-Receipts NICHT in Memory"
- `devops/hermes-maintenance` §11.4 — Hermes-CLI bash-background IOCTL-Quirk
- `note-taking/obsidian` — Obsidian Vault-Operationen (Sync zu Mnemosyne beachten)
- `references/beam-working-cleanup.md` — Vollständige Procedure mit Code + Session-Output + Debug-Erkenntnisse
- `scripts/mnemosyne-monthly-cleanup.sh` — Produktions-Cron-Skript (Template für weitere Hygiene-Crons)

## See Also

- `hermes-agent` skill: Memory provider configuration
- `system-documentation` skill: System state documentation
- Mnemosyne source: `~/.hermes/hermes-agent/venv/lib/python3.11/site-packages/mnemosyne/`
- `references/beam-working-cleanup.md` — Bulk Cleanup Step-by-Step Guide
- `scripts/mnemosyne-monthly-cleanup.sh` — Monatliches Cron-Cleanup-Skript
