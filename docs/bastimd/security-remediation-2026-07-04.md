# Security-Remediation-Liste — 2026-07-04

> **Grundlage:** MaxClaw Self-Audit (`/tmp/maxclaw-clone/security-audit-2026-07-04.md`)
> **Stand:** 2026-07-04 05:30 MESZ
> **Hermes-Schutz:** `~/.hermes/config.yaml` ist Agent-write-protected — diese Edits müssen via Basti selbst laufen (`hermes config edit` oder direkter Edit mit Root-Account).

---

## ✅ Bereits durch Agent gefixt

| Sev | Finding | Fix | Verifiziert |
|-----|---------|-----|------------|
| P0 | `P0.backup.secretref_exists` | MaxClaw `config.yaml` v3.0 → Hermes-native | ✅ maxclaw-config-check.sh grün |
| P0 | `P4.fs.world_writable` | `chmod o-w` auf 8 Lockfiles (uv, venv, hermes) | ✅ `ls -la` zeigt jetzt `o-w` |
| P0 | Hermes-cron Provider-Drift | 7 Jobs gepinnt via `cronjob action=update` | ✅ Alle Crons getestet, status=ok |
| P0 | Doppelte Crons (8 Stück) | `cronjob action=remove` für 11 veraltete IDs | ✅ hermes cron list clean |
| P0 | `greyhack-tool-builder` workdir=/tmp/MaxClaw (fehlte) | workdir → /tmp/maxclaw-clone | ✅ Live-Run grün |
| P0 | `greyhack-ci-watch` gelöscht (versehentlich bei cleanup) | Neu registriert via `--add`, ID `0de66e3162ec` | ✅ Live-Run grün |

## 🟡 Manuell durch Basti (via `hermes config edit`)

Hermes-Live-`config.yaml` ist Agent-Schreibgeschützt. Diese P1-Fixes brauchen User:

### 1. write_paths in Hermes-Config eintragen (P1)

Im Block `security:` folgendes einfügen:

```yaml
security:
  ...
  write_paths:
    - "~/greyhack-tools/"
    - "~/greyhack-tools/build/"
    - "~/greyhack-tools/mission-logs/"
    - "~/docs/"
    - "~/backups/"
    - "~/logs/"
    - "~/bin/"
    - "/tmp/maxclaw-clone/"
    - "/tmp/MaxClaw-sandbox/"
  deny_paths:
    - "/etc/"
    - "/var/"
    - "~/greyhack-tools/.git/"
    - "/mnt/DATA/Programme/Steam/"
    - "~/.ssh/id_*"
    - "~/.netrc"
    - "~/.gnupg/"
    - "~/greyhack-tools/binaries/malware/"
```

### 2. git-push-main als Deny (P1)

Hermes-interne `permissions.tools.terminal.deny` ergänzen um:

```yaml
permissions:
  tools:
    terminal:
      deny:
        - "git push*main*"
        - "git push*origin*main*"
        - "sudo*"
        - "rm -rf /"
        - "rm -rf /*"
        - "curl* | *sh"
```

### 3. monthly_limit_eur pro Provider (P1)

In den Provider-Configs jeweils ergänzen:

```yaml
models:
  main:
    monthly_limit_eur: 20
  heavy:
    monthly_limit_eur: 30
  heartbeat:
    monthly_limit_eur: 5
  subagent:
    monthly_limit_eur: 10
```

### 4. ufw aktivieren (P2 → Quick-Win)

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Erlaubte ausgehende Verbindungen:
sudo ufw allow out to api.telegram.org
sudo ufw allow out to api.openrouter.ai
sudo ufw allow out to ollama.com
sudo ufw allow out to github.com

sudo ufw enable
```

### 5. Unerklärte 0.0.0.0-Listener (P2)

Drei ungeklärte Listener gefunden — bitte prüfen:

| Port | Process | Bewertung |
|------|---------|-----------|
| `0.0.0.0:8765` | python3 GreyHack-Fileserver | ✅ gewollt (GreyHack-Tool-Deployment) |
| `0.0.0.0:8200` | unbekannt | ⚠️ investigieren — ggf. cache? |
| `127.0.0.1:631` | cupsd | ✅ gewollt (lokaler Drucker-Socket) |

Befehl: `sudo ss -tlnp | grep "0.0.0.0:8200"` → welcher Prozess?

---

## ✅ Nice-to-have Doku-Update

- [ ] Diese Datei nach Fix-Durchlauf löschen oder auf Status "✅ alles gefixt" setzen
- [ ] Mnemosyne-Triple: `claude-security-audit | has-finding | hermes-config-manual-edit-needed`
- [ ] Falls Basti keine Zeit hat: P1-Fixes nächste Session priorisiert
