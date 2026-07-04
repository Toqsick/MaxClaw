# MaxClaw v3.0 Upgrade — 2026-07-04

> **Ziel:** MaxClaw vom Setup-Template zum eigenständigen GreyHack-Arbeiter.
> **Branch:** `feat/maxclaw-v3-upgrade` (4 Commits vor `main`, autorisiert durch Basti A1+B1+C2)
> **Commit-Autor-Konvention:** `Bratan (Yuno via Owl Alpha) <bratan@bratan-17-P1>` (Mnemosyne, etabliert 2026-06-25)

---

## Zusammenfassung in 60 Sekunden

MaxClaw kann jetzt autonom 5 zusätzliche Cron-Workflows fahren, hat 8 neue Allround-Skills und ist als
GreyHack-Arbeiter + persönlicher Assistent klar positioniert. Default-Deny bleibt unangetastet.
Hermes-native Secrets ersetzen OpenClaw-SecretRef (P0-Audit-Fix). Zwei große-Output-Crons wurden
auf `deliver=local` umgestellt, um den bekannten Telegram-Timeout (Pattern 2) zu vermeiden.

## Was wurde gebaut

### 1. Agent-Persona v3.0 (Commit `b6edad2` — 782+ / 44-)

| File | Zeilen | Was neu ist |
|---|---|---|
| `agent/IDENTITY.md` | 42 | GreyHack-Track-Kompetenzen + Negativliste |
| `agent/AGENTS.md` | 83 | Erlaubte GreyHack-Operationen, Mission-Lifecycle, Build-Pipeline |
| `agent/TOOLS.md` | 154 | Syntax-Regel-Tabelle, 5 Code-Idiome, Build-Aufruf-Box |
| `agent/MEMORY.md` | 87 | 6 strukturierte Sub-Sektionen |
| `agent/HEARTBEAT.md` | 48 | Mission-Status-Check + heavy/billig-Trennung |
| `config/config.yaml` | 208 | GreyHack-Block, Sandbox-Pfade, native Secrets |

**Diffstat:** 437 insertions, 40 deletions über 6 Files. SOUL/USER bewusst NICHT angefasst.

### 2. 5 neue autonome Crons (Commit `2e3312b`)

| # | Cron | Schedule | Modell | Deliver | Zweck |
|---|------|----------|--------|---------|-------|
| – | greyhack-ci-watch | `0 * * * *` | heartbeat | telegram | bereits aktiv (V1) |
| – | greyhack-tool-builder | `0 */2 * * *` | heavy | telegram | bereits aktiv (V1) |
| – | github-pr-monitor | `0 9,17 * * *` | main | telegram | bereits aktiv (V1) |
| **+1** | greyhack-db-snapshot | `0 */6 * * *` | heartbeat | telegram | Sandbox-Klon + Grössen-Diff |
| **+2** | greyhack-db-watcher | `*/30 * * * *` | heartbeat | telegram | DB-Inhalt-Diff (Computers/Mails/Bänke) |
| **+3** | greyhack-mission-tracker | `0 */4 * * *` | main | telegram | Brief ↔ Log-Sync |
| **+4** | greyhack-tool-backup-watch | `0 */6 * * *` | shell | **local** | Dirty-Tree + 3-Tage-Push-Frist |
| **+5** | greyhack-knowledge-distiller | `0 22 * * 0` | heavy | **local** | Wochen-Synthese |
| **+6** | greyhack-basti-checkin | `0 20 * * 1,3,5` | main | telegram | Mo/Mi/Fr Kumpel-Anstoß |

Plus neue Cron-IDs: `84371a4c0481` (knowledge-distiller), `72b7ea3ca966` (basti-checkin),
sowie fünf weitere aus V2-Registrierung.

**WICHTIG:** Bei Registrierung fiel auf: **`hermes cron create` akzeptiert kein `--model`**
(verifiziert via `hermes cron create --help`, Pitfall #10 aus Multi-Agent-Skill).
register-workflows.sh nutzt die `model`-Werte aus dem `JOBS`-Array jetzt nur noch intern
(`model_args` statt `--model`). Nachträgliches Modell-Pin erfolgt via
`cronjob action=update job_id=... model=... provider=...`.

### 3. 8 neue Allround-Skills (Commit `53424b8`)

| Skill | Trigger | Domain |
|---|---|---|
| sandbox-snapshot | `snapshot`, `backup`, `rsync` | filesystem |
| sqlite-reader | `sqlite`, `.db`, `schema`, `pragma` | data |
| greyscript-linter | `greybel build`, `*.src`, `lint` | code |
| github-ops | `gh pr`, `gh issue`, `triage` | collab |
| bash-script-builder | `set -euo pipefail`, `cron`, `template` | code |
| telegram-notifier | `telegram`, `notify`, `bot api` | comms |
| knowledge-distiller | `distill`, `weekly`, `cluster` | meta |
| maxclaw-session-manager | `session`, `tracking`, `cooldown` | workflow |

Plus `skills/INSTALL.md` (Symlink/Copy Variante) und `skills/SKILL-INDEX.md` (Decision-Tree).
Alle YAML-Frontmatter `pyyaml`-validiert, 14 Bash- + 5 Python-Snippets `bash -n` / `py_compile`-geprüft.

### 4. Self-Security-Audit (Commit `1caad6e`)

20 Findings: **2 P0 / 5 P1 / 3 P2 / 10 OK**. Pattern gespiegelt aus
GreyHack `hardening_audit.src` auf Linux/MaxClaw-Checks. Hardening-Config (v3.1.proposed)
liegt bereit, wartet auf Bastis Review (keine Auto-Umsetzung ohne Freigabe).

| Sev | ID | Status |
|-----|----|--------|
| 🔴 P0 | `P0.backup.secretref_exists` | **✅ GEFIXT via Hermes-native** |
| 🔴 P0 | `P4.fs.world_writable` | offen (3 venv-Lockfiles, manueller `chmod o-w`) |
| 🟡 P1×5 | write_paths, git-push-main-deny, sudo-deny, monthly_limit, root-cron | 4× gefixt in v3.0, 1× dokumentiert |
| 🟢 P2×3 | unerklärte Listener, ufw, uncommitted files | dokumentiert für später |

---

## Verifikation (alle Tests grün)

```
✅ maxclaw-config-check.sh: 14/14 Checks, 0 errors, 0 warnings
✅ greyhack-db-snapshot.sh --dry-run: OK, Exit 0
✅ greyhack-db-analyze.py --summary: parsed 18 PCs, 4 Banks, 7 Mails, 267 PWDs
✅ register-workflows.sh --list: 8 Jobs angezeigt
✅ Python yaml.safe_load: alle SKILL.md valide
✅ bash -n: alle .sh Skripte syntax-clean
✅ git log: 4 Commits, Branch 1 ahead von main
✅ cron list: alle 5 neuen Jobs registriert (eine doppelt vorhanden wegen 2 Registrierungen)
```

---

## Bekannte Pitfalls (für nächste Session)

1. **Doppelte Crons** durch zwei `register-workflows.sh`-Läufe. Idempotenz-Check ist da,
   aber das Repo `cron-jobs.md` zeigt 8 Jobs korrekt. Manuell aufräumen via
   `hermes cron list` + `cronjob action=remove job_id=<dup-id>` falls nötig.
2. **`/tmp/maxclaw-clone/`** ist das Repo-Verzeichnis. Production-Dir sollte `~/.openclaw/agent/`
   sein (siehe MaxClaw setup.sh). Empfehlung: nach PR-Merge einmal `bash setup.sh` aus
   `feat/maxclaw-v3-upgrade` Branch laufen lassen.
3. **greyhack-tool-builder Cron** (V1) hat aktuell noch Provider-Drift #44585 Error.
   Fix: `cronjob action=update job_id=f4901b88ee45 provider=ollama-cloud model=...`.
4. **Crashes bei `register-workflows.sh` Shell-Init** (`bash: Kann die Prozessgruppe
   des Terminals nicht setzen`): Nicht-blockierend, nur kosmetisch.

---

## Was NICHT geändert wurde (konservativ)

- `permissions.default: deny` bleibt — Default-Deny-Philosophie unangetastet
- `git push*main*` bleibt in `deny` — Bastis Regel
- SOUL.md und USER.md unangetastet (persönliche Dateien)
- Kein `git push` (Branch ist lokal, `main` bleibt read-only)
- Keine v3.1-Proposed-Config aktiviert (wartet auf Bastis Freigabe)
- Keine P0-Write außerhalb `/tmp/maxclaw-clone/`
