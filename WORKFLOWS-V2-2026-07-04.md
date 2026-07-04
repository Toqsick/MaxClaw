# MaxClaw Workflows V2 — Übersicht & Begründung

> **Stand:** 2026-07-04 · **Autor:** MaxClaw-Workflow-Architekt (Queen-Pattern)
> **Scope:** Erweiterung der bestehenden 3 Crons um 5 neue autonome Workflows.

---

## 1. Ausgangslage (V1)

Drei Crons waren bisher aktiv (siehe `cron-jobs.md`):

| Cron | Schedule | Modell | Zweck |
|------|----------|--------|-------|
| `greyhack-ci-watch` | `0 * * * *` | heartbeat | Build-Status `greybel` auf `develop` |
| `greyhack-tool-builder` | `0 */2 * * *` | heavy | Sandbox-Refactoring autonom |
| `github-pr-monitor` | `0 9,17 * * *` | main | PR/Issue-Übersicht Toqsick-Repos |

Zusätzlich dokumentiert (aber nicht als Cron registriert): `daily-briefing.md`, `security-audit-weekly.md` — wurden aus der aktiven `cron-jobs.md` rausgenommen.

**Schwachstellen V1:**

1. **Reaktiv, nicht proaktiv** — der Agent arbeitet nur, wenn Basti crasht oder wenn Builds rot werden.
2. **Kein Spielwelt-Monitoring** — Basti verpasst Savegame-Events (Mails, Bank-Bewegungen).
3. **Kein Missions-Tracking** — `~/docs/system/greyhack-missions.md` und `~/greyhack-tools/MISSION-LOG.md`
   laufen auseinander.
4. **Kein Tool-Backup-Wächter** — Dirty-Working-Trees oder vergessene Pushes werden nicht bemerkt.
5. **Kein Wochen-Reflexion** — Erkenntnisse aus den Cron-Logs versickern, keine Synthese.
6. **Kein persönlicher Check-in** — Basti verliert nach Pausen den Faden.

## 2. Auswahl der 5 neuen Workflows (V2)

Jeder Workflow wurde nach drei Kriterien ausgewählt:

- **Watchdog-Pattern-Konformität:** silent on success, nur bei substantieller Änderung Telegram-Alarm.
- **Kostenbewusstsein:** `heartbeat` (deterministisch) > `main` (günstig) > `heavy` (teuer). Schwere Modelle
  nur, wenn Reasoning/Synthesis unvermeidlich ist.
- **Autonomiegewinn:** der Workflow erlaubt dem Agenten, **ohne Bastis Eingriff** sinnvolle Arbeit zu tun
  oder zumindest den Zustand zu beobachten.

### A) `greyhack-db-watcher` — Spielwelt-Monitoring

**Schedule:** `*/30 * * * *` · **Modell:** `heartbeat` (kein LLM — SQLite + Hash)
**Frequenz-Begründung:** 30 min ist fein genug, um Mails/Bank-Events zeitnah zu erwischen, ohne
Spam oder nennenswerte Kosten.
**Kosten:** ≈ 0 (heartbeat).
**Autonomie-Beitrag:** der Agent „beobachtet das Savegame" — ein für Basti mental hochfrequent
unbeobachtbarer Datenstrom wird in eine einzige Push-Nachricht destilliert.

### B) `greyhack-mission-tracker` — Brief ↔ Log Synchronisation

**Schedule:** `0 */4 * * *` · **Modell:** `main`
**Frequenz-Begründung:** 4 h ist der Sweet-Spot — nicht so oft, dass Basti bei laufendem Spiel
genervt wird, nicht so selten, dass Missions-Drift zur Woche wird.
**Kosten:** 6 LLM-Calls/Tag · `main` reicht für Diff-Reasoning.
**Autonomie-Beitrag:** ohne diesen Job müsste Basti die Drift manuell erkennen. Mit ihm bekommt
er alle 4 h sanft die Hand auf die Schulter.

### C) `greyhack-tool-backup-watch` — Repo-Hygiene

**Schedule:** `0 */6 * * *` · **Modell:** `shell` (kein LLM — Bash + git)
**Frequenz-Begründung:** Backup-Erinnerungen müssen regelmäßig sein, aber 6×/Tag ist genug
Platz, dass Basti nicht das Gefühl hat, der Agent nörgelt.
**Kosten:** ≈ 0 (reines Bash).
**Autonomie-Beitrag:** Plötzlicher Datenverlust ist Bastis Albtraum — dieser Wächter ist eine
„billige Versicherung". Schreibt zusätzlich `.backup-state` für den Knowledge-Distiller.

### D) `greyhack-knowledge-distiller` — Wochen-Synthese

**Schedule:** `0 22 * * 0` · **Modell:** `heavy`
**Frequenz-Begründung:** Sonntag 22 Uhr ist nach Spielzeit, alle Wochen-Inputs liegen vor.
**Kosten:** 1× Opus/Codex pro Woche — akzeptabel, weil außerhalb aktiver Stunden.
**Autonomie-Beitrag:** der Agent baut sich selbst ein wachsendes Domänen-Gedächtnis auf. Der
`skill-navigator`-Skill hilft beim Finden relevanter Refs, `multi-agent-orchestration` darf
für parallele Sub-Cluster-Analyse genutzt werden.

### E) `greyhack-basti-checkin` — Flow-Holder

**Schedule:** `0 20 * * 1,3,5` · **Modell:** `main`
**Frequenz-Begründung:** 3×/Woche ist Rhythmus ohne Reiz-Überflutung. Mo/Mi/Fr passt zu typischen
Spieltagen (Wochenende + Mid-Week).
**Kosten:** 3 LLM-Calls/Woche · `main` reicht (lockerer Ton, moderate Synthese).
**Autonomie-Beitrag:** Basti verliert nach Spiel-Pausen nicht den Faden — der Check-in liest
automatisch Sessions, yuno-tools-Änderungen und Mission-Status zusammen.

## 3. Cron-Plan (alle 8 Jobs)

| # | Cron | Schedule | Purpose | Modell |
|---|------|----------|---------|--------|
| 1 | `greyhack-ci-watch` | `0 * * * *` | Build-Status `greybel develop` | `heartbeat` |
| 2 | `greyhack-tool-builder` | `0 */2 * * *` | Sandbox-Refactoring autonom | `heavy` |
| 3 | `github-pr-monitor` | `0 9,17 * * *` | PRs/Issues Toqsick-Repos | `main` |
| 4 | `greyhack-db-watcher` | `*/30 * * * *` | Savegame-Diff, Mails/Bänke/Computer | `heartbeat` |
| 5 | `greyhack-mission-tracker` | `0 */4 * * *` | Brief ↔ Log Synchronisation | `main` |
| 6 | `greyhack-tool-backup-watch` | `0 */6 * * *` | Dirty-Tree + 3-d-Push-Frist | `shell` (Bash) |
| 7 | `greyhack-knowledge-distiller` | `0 22 * * 0` | Wochen-Synthese + Insights-File | `heavy` |
| 8 | `greyhack-basti-checkin` | `0 20 * * 1,3,5` | 3×/Wo Kumpel-Anstoß, Mo/Mi/Fr | `main` |

**Kosten-Klasse (grob):**
- `heartbeat` + `shell` (= #1, #4, #6): ≈ 0 €/Tag — billige Watchdogs.
- `main` (= #3, #5, #8): ca. 3–5 LLM-Calls/Tag (jeweils klein) — niedrige Kosten.
- `heavy` (= #2, #7): 12 + 1 Calls/Woche — moderat; gerechtfertigt durch hohe Hebel-Wirkung
  (autonomes Refactoring + Wochen-Synthese).

## 4. Design-Prinzipien — alle 8 Jobs

1. **Watchdog-Pattern** — `silent on success`. Telegram-Ausgaben erfolgen **nur** bei Alarm
   oder echtem Fortschritt. Das schützt vor Reiz-Abschaltung und hält die Signal-Ratio hoch.
2. **Idempotente Registrierung** — `register-workflows.sh` prüft via `hermes cron list`, ob der
   Job-Name schon existiert, und überspringt in dem Fall. Mehrfaches Ausführen = gleicher Zustand.
3. **Skills als Parameter** — LLM-Crons bekommen Skills via `--skill` mitgegeben; `--add NAME`
   erlaubt punktuelles Nachtragen, ohne alle 8 nochmal zu registrieren.
4. **Modell-Routing nach Schwere** — Build-Watch und Tool-Backup sind deterministisch (kein
   LLM). Mission-Diff und Check-in brauchen Reasoning (main). Refactoring und Wochen-Synthese
   sind die einzigen `heavy`-Kandidaten.
5. **Schreibstil-Konsistenz** — alle Outputs sind deutsch, knapp, ohne Floskeln. Der
   `yuno-user-preferences`-Skill ist explizit nur beim Check-in-Job angehängt (am stärksten
   personenbezogen), nicht bei den technischen Jobs.
6. **Komponierbarkeit** — der Knowledge-Distiller liest die Outputs der anderen 7 Crons und
   baut daraus die Wochen-Synthese. So entsteht ein wachsendes Domänen-Gedächtnis, ohne dass
   Basti Doku pflegen muss.

## 5. Datei-Inventar (was real existiert)

```
/tmp/maxclaw-clone/
├── workflows/
│   ├── greyhack-ci-watch.md           (V1, unverändert)
│   ├── greyhack-tool-builder.md       (V1, unverändert)
│   ├── github-pr-monitor.md           (V1, unverändert)
│   ├── daily-briefing.md              (V1, dokumentiert — derzeit nicht aktiv)
│   ├── security-audit-weekly.md       (V1, dokumentiert — derzeit nicht aktiv)
│   ├── greyhack-db-watcher.md         (V2, NEU)
│   ├── greyhack-mission-tracker.md    (V2, NEU)
│   ├── greyhack-tool-backup-watch.md  (V2, NEU)
│   ├── greyhack-knowledge-distiller.md(V2, NEU)
│   ├── greyhack-basti-checkin.md      (V2, NEU)
│   └── register-workflows.sh          (V2 UPDATE: 8 Jobs + --add + idempotent)
└── WORKFLOWS-V2-2026-07-04.md         (dieses Dokument)
```

## 6. Aktivierung

```bash
# Einmal: alle 8 Jobs registrieren
cd /tmp/maxclaw-clone
./workflows/register-workflows.sh

# Später: punktuell einen neuen Job nachziehen
./workflows/register-workflows.sh --add greyhack-knowledge-distiller

# Verifizieren
hermes cron list
```

`register-workflows.sh` schreibt nach erfolgreichem Lauf die `cron-jobs.md` automatisch neu —
kein Hand-Pflege-Aufwand.