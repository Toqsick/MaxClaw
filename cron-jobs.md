# Aktive MaxClaw Cron-Jobs

Automatisch von `./workflows/register-workflows.sh` generiert — nicht von Hand pflegen.

Letzte Registrierung: 2026-07-04 05:13:32

- **greyhack-tool-backup-watch** (`0 */6 * * *`) → `workflows/greyhack-tool-backup-watch.md`

Verifizieren: `hermes cron list`

## Hilfe
```bash
./workflows/register-workflows.sh              # alle 8 Jobs registrieren (idempotent)
./workflows/register-workflows.sh --add NAME   # nur einen Job registrieren
./workflows/register-workflows.sh --list       # alle Jobs auflisten
./workflows/register-workflows.sh --dry-run    # nur anzeigen, nichts anlegen
```
