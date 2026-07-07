# MaxClaw Tools — Operations-Werkzeuge (v3.0)

Vier Skripte, die während des v3.0-Upgrades (2026-07-04) entstanden und seither produktiv laufen.
Jedes ist ausführbar (`chmod +x`), syntax-geprüft (`bash -n` / `py_compile`), mit deutschen
Code-Kommentaren und **ausführlichem `--help`**.

| Tool | Sprache | Zweck | Aufruf |
|------|---------|-------|--------|
| `greyhack-db-snapshot.sh` | Bash | Erstellt + rotiert SQLite-Sandbox-Snapshots der GreyHack-DB. Watchdog-Pattern: silent on success. | `--dry-run`, `--force`, `--help` |
| `greyhack-db-analyze.py` | Python | Liest DB-Snapshot (immutable+ro), extrahiert Player-State, Mission-Status, Inventar als JSON. | `--summary`, `--json`, `--pretty`, `--player-only`, `-o FILE` |
| `maxclaw-security-audit.sh` | Bash | Self-Audit (6 Phasen, JSON-Output): write_paths, sudo, secret-Refs, git-push-main, Modell-Limits, world_writable | `--phase=N`, `--output=FILE`, `--help` |
| `maxclaw-config-check.sh` | Bash | Validiert `openclaw.json` + `exec-approvals.json` + `greyhack.yaml` (Invarianten; ruft `openclaw config validate`, falls vorhanden). | `[pfad/openclaw.json]` |

## Installation

```bash
# Alle Tools nach ~/bin/ installieren (übliche Position für Yuno-Skripte)
cp tools/*.sh tools/*.py ~/bin/
chmod +x ~/bin/greyhack-db-* ~/bin/maxclaw-*

# Test
~/bin/greyhack-db-snapshot.sh --dry-run --help
~/bin/greyhack-db-analyze.py --help
```

## Verwendung in MaxClaw-Crons

Diese Skripte sind über die **8 produktiven Crons** (siehe `workflows/`) eingebunden, werden
aber hauptsächlich direkt vom Agent benutzt:

- **`greyhack-db-snapshot.sh`** wird von Cron `greyhack-db-snapshot` aufgerufen (alle 6h).
- **`greyhack-db-sandbox-latest.db`** (Output) ist Input für **`greyhack-db-analyze.py`**.
- **`maxclaw-security-audit.sh`** läuft als `security-audit-weekly` Cron (Mo 09:00) sowie manuell.
- **`maxclaw-config-check.sh`** wird vom Agent VOR jedem `git commit` ausgeführt (Hook).

## Test-Output (Stand 2026-07-04)

```
$ bash -n tools/greyhack-db-snapshot.sh && echo OK
OK
$ bash -n tools/maxclaw-config-check.sh && echo OK
OK
$ bash -n tools/maxclaw-security-audit.sh && echo OK
OK
$ python3 -c "import py_compile; py_compile.compile('tools/greyhack-db-analyze.py', doraise=True)" && echo OK
OK

$ tools/greyhack-db-snapshot.sh --dry-run
ℹ️  Original-DB: 6.66 MB
ℹ️  Kein vorheriger Snapshot gefunden — erster Lauf.
── DRY-RUN — keine Änderungen ──
  Anomalie: ✅ NEIN
  Exit 0
```

## Dependencies

- Bash >= 4.0
- Python >= 3.9 (für `sqlite3`-Modul + `argparse`)
- `sqlite3` CLI (vorinstalliert)
- Optional: `yq` (für YAML-Parsing in `maxclaw-config-check.sh`) — Fallback nutzt Python

## Wartung

Werden per Hand gepflegt (nicht durch Cron auto-modifiziert). Updates: direkter `git pull`
+ `cp tools/* ~/bin/`.

## Real-Lifecycle-Beispiel

```bash
# Workflow: "DB-Watcher erkennt neue Mail"
~/bin/greyhack-db-snapshot.sh                # macht neue Sandbox-Kopie
sqlite3 ~/backups/greyhack/sandbox-latest.db "SELECT * FROM MailAccounts" # schneller Check
~/bin/greyhack-db-analyze.py ~/backups/greyhack/sandbox-latest.db --summary  # JSON-Report
~/bin/greyhack-db-analyze.py ~/backups/greyhack/sandbox-latest.db --pretty  # human-readable
```
