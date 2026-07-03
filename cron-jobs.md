# Aktive MaxClaw Cron-Jobs

Automatisch von `./workflows/register-workflows.sh` generiert — nicht von Hand pflegen.

Letzte Registrierung: 2026-07-04 00:03:38

- **greyhack-ci-watch** (`0 * * * *`) → `workflows/greyhack-ci-watch.md`
- **greyhack-tool-builder** (`0 */2 * * *`) → `workflows/greyhack-tool-builder.md`
- **github-pr-monitor** (`0 9,17 * * *`) → `workflows/github-pr-monitor.md`

Verifizieren: `hermes cron list`
