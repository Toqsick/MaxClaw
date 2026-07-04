# Aktive MaxClaw Cron-Jobs

Automatisch von `./workflows/register-workflows.sh` generiert — nicht von Hand pflegen.

Letzte Registrierung: 2026-07-04 04:54:45

- **greyhack-ci-watch** (`0 * * * *`) → `workflows/greyhack-ci-watch.md`
- **greyhack-tool-builder** (`0 */2 * * *`) → `workflows/greyhack-tool-builder.md`
- **github-pr-monitor** (`0 9,17 * * *`) → `workflows/github-pr-monitor.md`
- **greyhack-db-watcher** (`*/30 * * * *`) → `workflows/greyhack-db-watcher.md`
- **greyhack-mission-tracker** (`0 */4 * * *`) → `workflows/greyhack-mission-tracker.md`
- **greyhack-tool-backup-watch** (`0 */6 * * *`) → `workflows/greyhack-tool-backup-watch.md`
- **greyhack-knowledge-distiller** (`0 22 * * 0`) → `workflows/greyhack-knowledge-distiller.md`
- **greyhack-basti-checkin** (`0 20 * * 1,3,5`) → `workflows/greyhack-basti-checkin.md`

Verifizieren: `hermes cron list`

## Hilfe
```bash
./workflows/register-workflows.sh              # alle 8 Jobs registrieren (idempotent)
./workflows/register-workflows.sh --add NAME   # nur einen Job registrieren
./workflows/register-workflows.sh --list       # alle Jobs auflisten
./workflows/register-workflows.sh --dry-run    # nur anzeigen, nichts anlegen
```
