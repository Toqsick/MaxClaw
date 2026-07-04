# 🦾 MaxClaw — v3.0

> **MaxClaw** = die [OpenClaw](https://openclaw.ai)-Instanz von **minimax / Nous Research**,
> aufgesetzt für Bastis Projekte — und mit v3.0 zum eigenständigen **GreyHack-Arbeiter + persönlichen Assistenten** weiterentwickelt.
> Dieses Repo ist **Setup + Nutzung + automatische Workflows + Skills + Security-Vorlagen** —
> als lauffähige Vorlage, nicht als bloße Beschreibung.

MaxClaw ist ein **persönlicher KI-Agent**, der auf einem eigenen Rechner/Server läuft,
vollen Zugriff auf seine Arbeitsumgebung hat, sich mit deinen Tools verbindet und
**proaktiv** im Hintergrund arbeitet — während du etwas anderes machst.

Anders als ein Chatbot (ChatGPT, Claude, Gemini), der nur im Chatfenster antwortet und
auf dich wartet, ist MaxClaw ein **Mitarbeiter mit eigenem Schreibtisch**: er erstellt Dateien,
führt Programme aus, surft im Netz, ruft APIs an, erweitert seine eigenen Fähigkeiten und
kommt von sich aus auf dich zu (z. B. per Telegram).

---

## 🆕 Was ist neu in v3.0 (2026-07-04)

| Bereich | v2 → v3.0 | Datei |
|---------|-----------|-------|
| **Agent-Persona** | Plain Agent → **GreyHack-Arbeiter + Assistent** (GreyHack-Track + Negativliste) | [`agent/IDENTITY.md`](agent/IDENTITY.md), [`agent/AGENTS.md`](agent/AGENTS.md) |
| **Config-Secrets** | OpenClaw-SecretRef (`~/.openclaw/out/`) → **Hermes-native** (`~/.hermes/auth.json`, 0600, 90-Tage Rotation) | [`config/config.yaml`](config/config.yaml) |
| **Workflows** | 3 Crons → **8 Crons** (DB-Snapshot/-Watcher, Mission-Tracker, Tool-Backup-Watch, Knowledge-Distiller, Basti-Checkin) | [`workflows/`](workflows/) |
| **Skills** | 1 Sample → **9 produktive Skills** (8 Allround + 1 Hermes-Quirks + 1 Sample) | [`skills/`](skills/) |
| **Tools** | Lokal in `~/bin/` → **als `tools/` im Repo versioniert** | [`tools/`](tools/) |
| **Docs-Layer** | keine Sammlung → **`docs/bastimd/` + `docs/reports/`** für Verifikations-Dokus | [`docs/bastimd/`](docs/bastimd/), [`docs/reports/`](docs/reports/) |
| **Security-Audit** | Vorlagen-Fantasie → **20 echte Findings** mit Patch-Vorlage | [`security/security-audit-2026-07-04.md`](security/security-audit-2026-07-04.md) |

> 📜 Detaillierte Änderungen: [`AGENT-UPGRADE-2026-07-04.md`](AGENT-UPGRADE-2026-07-04.md) (339 Zeilen Diff-Begründung)

---

## 📚 Der Kurs — 8 Blöcke

Nachgebaut nach dem Video *„OpenClaw Kurs für Einsteiger: Alle Konzepte einfach erklärt"*,
aber konkret auf **MaxClaw v3.0** und unsere Projekte gemünzt.

| # | Block | Datei | Was du danach kannst |
|---|-------|-------|----------------------|
| 1 | Grundlagen & Installation | [docs/01-grundlagen.md](docs/01-grundlagen.md) | Was MaxClaw ist, wo man es installiert |
| 2 | Kosten & Modelle | [docs/02-kosten-und-modelle.md](docs/02-kosten-und-modelle.md) | API-Key vs. OAuth, Modell-Routing, Kosten begrenzen |
| 3 | Das Gehirn des Agenten | [docs/03-das-gehirn.md](docs/03-das-gehirn.md) | Soul/Identity/Agents/User/Tools/Memory verstehen |
| 4 | Kommunikation & Multi-Agent | [docs/04-kommunikation-multiagent.md](docs/04-kommunikation-multiagent.md) | Gateway, Channels, Sessions, Subagenten + Queen-Pattern |
| 5 | Automatisierung | [docs/05-automatisierung.md](docs/05-automatisierung.md) | **Heartbeat & 8 Cron-Jobs** |
| 6 | Erweiterungen | [docs/06-erweiterungen.md](docs/06-erweiterungen.md) | **9 Skills** + Plugins + MCP + CLI-Tools |
| 7 | Security & Risiken | [docs/07-security.md](docs/07-security.md) | Hermes-native Secrets, **Audit-Findings**, Default-Deny |
| 8 | Server-Deployment | [docs/08-server-deployment.md](docs/08-server-deployment.md) | VPS + Docker + Reverse Proxy sicher aufsetzen |

---

## 🗂️ Repo-Struktur (v3.0)

```
MaxClaw/                                          ← du bist hier
├── README.md                                     ← diese Datei
├── setup.sh                                      ← One-Command-Setup (kopiert Vorlagen)
├── AGENT-UPGRADE-2026-07-04.md                   ← NEU v3.0 Changelog (339 Zeilen)
├── WORKFLOWS-V2-2026-07-04.md                    ← NEU v3.0 Workflow-Übersicht
├── security-audit-2026-07-04.md                  ← NEU v3.0 Security-Audit-Report
│
├── docs/                                         ← der 8-Block-Kurs
│   ├── 01-grundlagen.md          bis 08-server-deployment.md
│
├── agent/                                        ← NEU v3.0: GreyHack-Arbeiter-Persona
│   ├── SOUL.md                   ← unverändert (persönlich)
│   ├── IDENTITY.md               ← v3.0: GreyHack-Track-Kompetenzen
│   ├── AGENTS.md                 ← v3.0: GreyHack-Operationen + Mission-Lifecycle
│   ├── USER.md                   ← unverändert
│   ├── TOOLS.md                  ← v3.0: Syntax-Regel-Tabelle + 5 Code-Idiome
│   ├── MEMORY.md                 ← v3.0: 6 Sub-Sektionen
│   └── HEARTBEAT.md              ← v3.0: heavy/billig-Trennung
│
├── config/
│   ├── config.yaml               ← v3.0: Hermes-native Secrets + GreyHack-Block
│   └── config.yaml.v3.1.proposed ← NEU: gehärtete Config (Review ausstehend)
│
├── workflows/                                    ← 8 produktive Crons (siehe docs/05)
│   ├── daily-briefing.md                         (07:00 Briefing per Telegram)
│   ├── greyhack-ci-watch.md                      (stündlich — greybel-Build-Wächter)
│   ├── greyhack-tool-builder.md                  (alle 2h — Sandbox-Refactoring)
│   ├── github-pr-monitor.md                      (9 + 17 Uhr — PRs/Issues Toqsick-Repos)
│   ├── greyhack-db-snapshot.md                   ← NEU (alle 6h — DB-Sandbox-Snapshot)
│   ├── greyhack-db-watcher.md                    ← NEU (*/30min — DB-Diff Watch)
│   ├── greyhack-mission-tracker.md               ← NEU (alle 4h — Brief↔Log-Sync)
│   ├── greyhack-tool-backup-watch.md             ← NEU (alle 6h — Dirty-Tree + 3d-Push)
│   ├── greyhack-knowledge-distiller.md           ← NEU (So 22h — Wochen-Synthese)
│   ├── greyhack-basti-checkin.md                 ← NEU (Mo/Mi/Fr 20h — Kumpel-Anstoß)
│   ├── security-audit-weekly.md                  (Mo 09:00 — Read-only Audit)
│   └── register-workflows.sh                     ← v3.0: 8 Jobs + --add/--list/--dry-run
│
├── skills/                                       ← NEU v3.0: 9 produktive Skills
│   ├── SKILL-INDEX.md                            ← Decision-Tree
│   ├── INSTALL.md                                ← Installations-Anleitung
│   ├── project-doc-sync/                         ← (Original v2 Sample)
│   ├── sandbox-snapshot/                         ← NEU: rsync+hardlink Rotation
│   ├── sqlite-reader/                            ← NEU: mode=ro+immutable=1 + FK-Discovery
│   ├── greyscript-linter/                        ← NEU: Static-Analysis VOR greybel build
│   ├── github-ops/                               ← NEU: gh CLI PRs/Issues/Triage
│   ├── bash-script-builder/                      ← NEU: set -euo pipefail Template
│   ├── telegram-notifier/                        ← NEU: Markdown→HTML + Watchdog
│   ├── knowledge-distiller/                      ← NEU: Cluster/Top-N/Skill-Vorschläge
│   ├── maxclaw-session-manager/                  ← NEU: JSONL + fcntl Lock
│   └── hermes-cli-quirks/                        ← NEU v3.0: Hermes-CLI Pitfalls (#44585, gh-Pull-Request-Bug)
│
├── tools/                                        ← NEU v3.0: Operations-Werkzeuge
│   ├── README.md                                 ← Tools-Übersicht + Install-Befehle
│   ├── greyhack-db-snapshot.sh                   ← DB-Sandbox-Snapshot (Watchdog)
│   ├── greyhack-db-analyze.py                    ← DB-Inhalts-Extrakt (JSON)
│   ├── maxclaw-security-audit.sh                 ← Self-Hardening (6 Phasen)
│   └── maxclaw-config-check.sh                   ← Validierung config.yaml (14 Checks)
│
├── docs/                                         ← der 8-Block-Kurs + Verifikations-Layer
│   ├── 01-grundlagen.md          bis 08-server-deployment.md
│   ├── bastimd/                                       ← User-Aktion-Dokus
│   │   ├── maxclaw-v3-upgrade-2026-07-04.md
│   │   ├── greyhack-db-snapshot-2026-07-04.md
│   │   └── security-remediation-2026-07-04.md
│   └── reports/                                       ← v3.0-Reports
│       ├── agent-upgrade-2026-07-04.md
│       ├── security-audit-2026-07-04.md
│       └── greyhack-weekly-insights-2026-07-04.md
│
├── security/                                     ← NEU v3.0: Security-Pattern gespiegelt
│   ├── policies.md                               ← was darf MaxClaw (Begründung)
│   ├── hardening_audit_maxclaw.yaml              ← Self-Hardening-Config
│   └── key_rotation.md                           ← Secret-Lebenszyklus, 90d Rotation
│
├── cron-jobs.md                                  ← aktive Crons (auto-gen)
└── .gitignore
```

---

## ⚡ Quickstart (für MaxClaw v3.0)

```bash
# 1. Repo holen
git clone https://github.com/Toqsick/MaxClaw.git
cd MaxClaw

# 2. Setup ausführen (legt Vorlagen im MaxClaw-Workspace an)
./setup.sh

# 3. (v3.0) Skills installieren — siehe skills/INSTALL.md
# Symlink in den Hermes-Skill-Pfad:
./skills/INSTALL.md       # zeigt die genauen Befehle

# 4. (Optional) Workflows als Cron-Jobs registrieren
./workflows/register-workflows.sh --list         # 8 Workflows anzeigen
./workflows/register-workflows.sh                # alle 8 idempotent registrieren
./workflows/register-workflows.sh --add NAME     # nur eine (z.B. nur greyhack-db-watcher)
./workflows/register-workflows.sh --dry-run      # nur anzeigen, nichts anlegen
```

> ⚠️ **Sicherheit zuerst:** Lies **[docs/07-security.md](docs/07-security.md)**, bevor du MaxClaw
> Zugriff auf sensible Tools gibst. MaxClaw ist ein *„Praktikant mit Superkräften"* —
> extrem nützlich, aber schau immer drüber, was er tut. Keine geschäftskritischen Prozesse.

---

## 🎯 Unsere konkreten Auto-Workflows (8 Crons)

MaxClaw ist bei uns kein Spielzeug — er hält diese Projekte am Laufen:

### Watchdogs (Watchdog-Pattern: silent on success)

| Workflow | Takt | Was |
|----------|------|-----|
| **greyhack-ci-watch** | stündlich | `greybel build` nach jedem Commit grün? |
| **greyhack-db-watcher** | */30 min | DB-Diff (neue Computer, Mails, Bank-Tx) |
| **greyhack-tool-backup-watch** | alle 6h | `git status` dirty? Push > 3 Tage? |

### Proaktiv (geben Antworten)

| Workflow | Takt | Was |
|----------|------|-----|
| **daily-briefing** | tägl. 07:00 | Kompaktes Briefing per Telegram |
| **greyhack-tool-builder** | alle 2h | Sandbox-Refactoring, 1 Baustelle pro Lauf |
| **github-pr-monitor** | 09:00 + 17:00 | PRs/Issues Toqsick-Repos |
| **greyhack-mission-tracker** | alle 4h | Brief ↔ MISSION-LOG sync, freundlich erinnern |
| **greyhack-basti-checkin** | Mo/Mi/Fr 20h | Kumpel-Anstoß, Maximal 12 Zeilen Telegram |
| **greyhack-knowledge-distiller** | So 22h | Wochen-Synthese → `~/docs/system/greyhack-weekly-insights-*.md` |
| **greyhack-db-snapshot** | alle 6h | Sandbox-Clone in `~/backups/greyhack/` |
| **security-audit-weekly** | Mo 09:00 | Read-only Audit Desktop + GCP VM |

> 📐 **Cost-Klassen:** Watchdogs ≈ 0 €/Mon (deterministisch). `basti-checkin`/`mission-tracker` ≈ 3–5 `main`-Calls/Tag. `tool-builder` + `knowledge-distiller` = die einzigen `heavy`-Kandidaten, hoher Hebel.
> 📁 Detail-Prompts im Ordner [`workflows/`](workflows/).

---

## 🛠️ Skills v3.0 — Allround-Toolkit

9 produktive Skills, jeder mit **lauffähigem Code** und YAML-Frontmatter. Decision-Tree
in [`skills/SKILL-INDEX.md`](skills/SKILL-INDEX.md). Installation: [`skills/INSTALL.md`](skills/INSTALL.md).

| Skill | Trigger | Domain |
|-------|---------|--------|
| `sandbox-snapshot` | snapshot, backup, restore, rsync, hardlink | filesystem |
| `sqlite-reader` | sqlite, .db, schema, pragma, foreign_key | data |
| `greyscript-linter` | greybel build, *.src, pre-commit, lint | code |
| `github-ops` | gh pr, gh issue, triage, conflict, rebase | collaboration |
| `bash-script-builder` | bash, set -euo pipefail, cron, helper | code |
| `telegram-notifier` | telegram, notify, alert, watchdog | comms |
| `knowledge-distiller` | distill, weekly review, cluster | meta |
| `maxclaw-session-manager` | session, tracking, lock, cooldown | workflow |
| `hermes-cli-quirks` | hermes cron, cronjob action, provider drift, #44585 | ops/meta |
| `project-doc-sync` | docs, sync, system-documentation | docs |

### Wann welchen Skill laden?

```
Basti-Aufgabe                  →  Skill
─────────────────────────────────────────────────────────────────────
"mache DB-Backup"              →  sandbox-snapshot
"lies GreyHack-DB"             →  sqlite-reader + greyhack
"baue Tool X"                  →  greyscript-linter + greyhack
"öffne PR Toqsick/MaxClaw"     →  github-ops + github-pr-monitor
"neues Bash-Script"            →  bash-script-builder
"schick mir Telegram-Alert"    →  telegram-notifier
"was war in der Woche los?"    →  knowledge-distiller
"track diese Cron-Runs"        →  maxclaw-session-manager
"halt ~/docs/system/ aktuell"  →  project-doc-sync
```

---

## 🎮 GreyHack-Arbeits-Pattern

MaxClaw ist explizit für die GreyHack-Pipeline optimiert:

### Build-Pipeline
```bash
cd ~/greyhack-tools && python3 -m http.server 8765 &      # Fileserver
# In-Game:  pc.wget("http://127.0.0.1:8765/tool.src", "/tmp/tool.src")
#           shell.build("/tmp/tool.src")
```

### Build-Regeln (GreyScript)
- ✅ `greybel build` **OHNE** `-u` (Inline-if + Einzeiler-if broken)
- ✅ `//command: <name>` als **erste Zeile** jedes `.src`-Files (Pflicht)
- ❌ NIEMALS `str_repeat()`, `is_folder()` (gibt's nicht), HTTP-Requests (GreyScript-Limit)
- ❌ NIEMALS Negativ-Indices oder `'a' > 'b'` String-Compare (GreyScript 1.5.1)

### Sandbox-Clone (GreyHackDB)
- Quelle: `/mnt/DATA/Programme/Steam/steamapps/common/Grey Hack/Grey Hack_Data/GreyHackDB.db`
- Snapshot-Skript: `~/bin/greyhack-db-snapshot.sh` (alle 6h, Rotation letzte 7)
- Analyse-Tool: `~/bin/greyhack-db-analyze.py --summary` (Spieler-State, Mission-Status)

Siehe auch [`workflows/greyhack-*.md`](workflows/) für die volle Workflow-Liste.

---

## 🔐 Security (v3.0 — neue Architektur)

**Defaults sind strikt:**
- `permissions.default: deny`
- `permissions.tools.terminal.deny` enthält: `rm -rf*`, `git push*main*`, `sudo*`, `curl* | *sh`
- `permissions.tools.browser.enabled: false` (Prompt-Injection-Schutz)
- `secrets.backend: hermes_native` mit `~/.hermes/auth.json` (mode 0600)
- `secrets.rotation_days: 90`
- `confirmations.require_before`: send_message, publish, delete_outside_workspace, git_push_main,
  greyhack_strike, greyhack_money_transfer, greyhack_account_delete

**Audit-Durchlauf 2026-07-04:** 20 Findings, davon 2 P0, 5 P1, 3 P2, 10 OK.
Siehe [`security-audit-2026-07-04.md`](security-audit-2026-07-04.md).
Pattern gespiegelt aus `greyhack-tools/hardening_audit.src`.

**Unser Vorgehen:** Erst Lesen (read-only), dann priorisierten Report, dann Fixes **nur nach
expliziter Freigabe**. Service-Deaktivierung ok wenn Begründung klar. Ollama-Modelle nicht blind
löschen.

---

## 🧰 Operations-Werkzeuge (vom Build-Vorgang beigelegt)

| Tool | Zweck | Pfad |
|------|-------|------|
| `maxclaw-config-check.sh` | Validiert `config.yaml` (14 Checks) | `~/bin/maxclaw-config-check.sh` |
| `maxclaw-security-audit.sh` | Self-Hardening (6 Phasen, JSON-Output) | `~/bin/maxclaw-security-audit.sh` |
| `greyhack-db-snapshot.sh` | DB-Sandbox-Snapshot (Watchdog) | `~/bin/greyhack-db-snapshot.sh` |
| `greyhack-db-analyze.py` | DB-Inhalts-Extrakt (JSON-Output) | `~/bin/greyhack-db-analyze.py` |
| `register-workflows.sh` | Cron-Registrierung (8 Jobs, idempotent) | `workflows/register-workflows.sh` |

---

## 🐝 Multi-Agent-Orchestration (das eigentliche Lernziel)

> MaxClaw ist **Testlabor** für allgemeine Multi-Agent-Orchestration. GreyHack ist nicht
> das Ziel — Übung der **Queen-Bee-Metapher** ist es: die Königin (starkes Modell) befehligt
> den Schwarm (Subagenten mit kleinem/kostenlosem Modell).

### Pattern (5-Phasen-Queen-Workflow)

```
Phase 1: Parallel Research  (3-5 Subagenten, ~5-10 min)
Phase 2: Immediate Fixes    (parallel zum Eltern-Agent)
Phase 3: Synthesis          (merge + cross-check)
Phase 3.5: User-Anker       (2-4 Optionen zur Wahl)
Phase 4: Execute & Document (P0 first)
Phase 5: Retrospective      (was worked, was not)
```

`delegate_task` mit `tasks=[...]` für 5 parallele Subagenten wurde bei diesem v3.0-Upgrade
eingesetzt — siehe `AGENT-UPGRADE-2026-07-04.md` für die 5 Phasen.

---

## 📊 Aktueller Stand (v3.0 — 2026-07-04)

- ✅ **8 MaxClaw-Crons aktiv** (alle live-getestet, status=ok)
- ✅ **9 Skills** produktiv (8 neue + 1 Sample)
- ✅ **20 Security-Findings** dokumentiert mit Patch-Vorlage
- ✅ **Hermes-native Secrets** statt OpenClaw-SecretRef (P0-Audit-Fix)
- ✅ **DB-Sandbox-Pipeline** (Snapshot alle 6h, Diff alle 30min)
- ✅ **GreyHack-Arbeiter-Persona** mit klarer Negativliste
- ⚠️ **P1-Fixes** in `~/hermes/config.yaml` brauchen Basti manuell via `hermes config edit`
  (siehe `~/docs/system/security-remediation-2026-07-04.md`)

---

*Erstellt als lauffähige Vorlage, kontinuierlich weiterentwickelt. Kommentare & Config auf Deutsch.
Stand: 2026-07-04 (v3.0). Übernommen aus dem [OpenClaw-Kurs](https://openclaw.ai).*
