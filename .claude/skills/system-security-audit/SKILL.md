---
name: system-security-audit
description: 'Linux-Sicherheitsaudit: offene Ports, Dienste, Berechtigungen, Firewall, Benutzer, Updates, schnelle Fixes.
  Mit Dokumentation.'
version: 1.0.0
author: Yuno
license: MIT
lane: worker-heavy
reasoning_effort: xhigh
---
# System Security Audit

Führe diesen Audit durch, wenn der Benutzer nach Sicherheit, Absicherung, offenen Ports, oder "was kann man schnell lösen" fragt.

## Ablauf

### 0. Multi-Scout Reconnaissance (optional, empfohlen)

**Wann:** System ist unbekannt, breiter Check gewünscht, "system check" oder "gib mir einen Überblick".
**Was:** 5 parallele Subagenten (delegate_task) scannen unabhängig verschiedene Aspekte.

**Scout-Zuordnung:**

| Scout | Fokus | Fragestellungen |
|-------|-------|-----------------|
| Scout 1 | Hardware & Disk | CPU/RAM/Disk-Belegung, Temperaturen, SMART-Health, Load |
| Scout 2 | Services & Container | systemd-Units, Docker, Cron, OOM-Kills, uptime, Failed-Units |
| Scout 3 | Security & Ports | offene Ports, Firewall-Status, SUID, sudoers (NOPASSWD), fail2ban |
| Scout 4 | Performance & Logs | System-Load, I/O-Wait, Log-Größe, dmesg-Errors, Swap, Kernel-Messages |
| Scout 5 | Network & Connectivity | Ping RTT, DNS, HTTPS-Erreichbarkeit, VPN-Status, Netzwerk-Interfaces |

**Ablauf:**
1. **Parallel feuern** — 5 Scouts über `delegate_task(tasks=[...])` starten
2. **Reports konsolidieren** — Ergebnisse aus allen Scouts lesen
3. **Scout-Bias erkennen** — Scouts übertreiben bewusst ("Gelb" = "Check mal selbst, vermutlich harmlos")
4. **Deep Dive** — Jede Gelb-Flagge mit eigenem `terminal()` verifizieren (ohne sudo wo möglich)
5. **Sortieren** — Befunde in "ohne sudo ziehbar" vs "braucht sudo" gruppieren
6. **Sudo-Sammlung erstellen** — alle sudo-Befehle in ein Script packen (siehe Sudo-Sammlung Pattern)

**Wichtig:** Scouts können nicht sagen "das braucht sudo" — sie haben keinen Terminal-Zugriff.
Die Grenze "ohne sudo" vs "mit sudo" findest du erst in deinem eigenen Deep Dive heraus.

#### Ausgabe-Erwartung

Gib am Ende **keine** offene Frage ("soll ich das machen?"). Stattdessen liefere:
- Klare Liste der **ohne-sudo** Befunde (copy-paste-ready zum eigenen Ausführen)
- Klare Liste der **sudo-Befunde** als strukturiertes Script (siehe Sudo-Sammlung Pattern)
- Kein "vielleicht", kein "wenn du willst"

### Risiko-Sternchen für Sudo-Befehle

Jeder Befehl in der Sudo-Sammlung bekommt ein Sternchen-Rating:

| Symbol | Bedeutung | Beispiele |
|--------|-----------|-----------|
| ⭐ | read-only, kein System-Eingriff | `sudo ss -tlnp`, `sudo dmesg`, `sudo smartctl -H` |
| ⭐⭐ | ändert temporären Zustand, reversibel | `journalctl --vacuum-size=200M`, `apt install`, Log-Rotation |
| ⭐⭐⭐ | schreibt Configs, deaktiviert Dienste, persistent | `systemctl mask`, `iptables -A`, `ufw deny` |

Aus dem Rating folgt die Empfehlung: ⭐ immer sicher, ⭐⭐ nach kurzer Info ausführbar,
⭐⭐⭐ nur nach Zustimmung. Aber **nie** als offene Frage — als Info-Kommentar im Script.

### Sudo-Sammlung Pattern (Copy-Paste-Ready)

Sobald alle Deep-Dives durch sind und die sudo-Befehle feststehen: **ein einzelnes Script**
schreiben, das alle Befehle in nummerierten Blöcken mit Kommentaren enthält.

**Struktur:**
```bash
#!/bin/bash
set -euo pipefail

echo "═══════════════════════════════════"
echo "  BLOCK 1 — Diagnose-Lücken · ⭐"
echo "═══════════════════════════════════"
# Warum: Port 3000 lauscht world-bound, kein Prozessname ohne root
sudo ss -ltnp 'sport = :3000 or sport = :8200'

echo ""
echo "═══════════════════════════════════"
echo "  BLOCK 2 — Journal Vacuum · ⭐⭐"
echo "═══════════════════════════════════"
# Warum: 4.4 GB syslog, 356 MB journal — gibt ~200 MB frei
sudo journalctl --vacuum-size=200M --vacuum-time=7d
```

**Regeln:**
- Jeder Block hat einen Header mit Risiko-Sternchen
- Jeder Befehl hat einen Kommentar **warum** er da steht
- Kein `set -x` — der User soll lesen können, nicht rauschen sehen
- Gefährliche Blöcke sind auskommentiert (nur als Vorlage, nicht auto)
- Kein `sudo -v`-Prompt, kein Expect, kein Script das nach Passwort fragt
- Das Script wird nach `~/Documents/` gespeichert, nicht nach `/tmp/`
- Der User ruft es selbst auf: `bash ~/Documents/sudo-sammlung-*.sh`

**Beziehung zu linux-system-maintenance:** Die Sudo-Sammlung ist der Endpunkt
der System-Check-Pipeline. Der `linux-system-maintenance` Skill deckt das
eigentliche Disk-Cleanup ab (no-sudo first → sudo cleanups → document).
Die Sudo-Sammlung hier ist **reine Diagnose**, kein Cleanup.

### 1. Netzwerk & offene Ports

```bash

set -euo pipefail
# Firewall-Status
sudo ufw status

# Offene Ports (lauschende Dienste)
ss -tlnp

# Dienste die auf 0.0.0.0 lauschen (von außen erreichbar!)
ss -tlnp | grep -E "0.0.0.0:|:::|:\*"

# SSH-Server prüfen
systemctl is-active sshd
```

Für jeden Dienst auf `0.0.0.0:` prüfen: Braucht der wirklich Netzwerkzugriff? Sonst auf localhost beschränken per UFW oder Config.

### 2. Berechtigungen

```bash

set -euo pipefail
# Sensitive Configs
ls -la ~/.gmail-organizer.json  # sollte 600 sein
ls -la ~/.hermes/config.yaml     # sollte 600 sein
ls -la ~/.ssh/                   # sollte 700 sein, keine fremden Keys

# HERMES-SPEZIFISCH: Session-DB, Logs, Snapshots
# state.db enthält den kompletten Sitzungsverlauf (~90MB+)
ls -la ~/.hermes/state.db ~/.hermes/kanban.db
# → sollten 600 sein (waren 644 = world-readable!)

# Logs können API-Keys und Tokens enthalten
ls -la ~/.hermes/logs/
# → agent.log, errors.log sollten 600 sein

# Snapshots = Session-Backups (ebenfalls sensitiv!)
ls -lad ~/.hermes/state-snapshots/
ls -la ~/.hermes/state-snapshots/ 2>/dev/null | head -5
# → Verzeichnis sollte 700 sein, dateien 600

# Config-Backups (enthalten oft API-Keys)
ls -la ~/.hermes/config.yaml.bak.* 2>/dev/null
# → sollten 600 sein

# Sicherheitslücken-Ranking: state.db > logs > snapshots > config-backups

# Weltlesbare Dateien in $HOME (außer .py, .md, .txt, Bilder)
find ~ -maxdepth 2 -type f -perm -o+r ! -name "*.py" ! -name "*.md" ! -name "*.txt" 2>/dev/null | head -20
```

### 3. Dienste & Autostart

```bash

set -euo pipefail
# Alle laufenden Dienste
systemctl list-units --type=service --state=running | head -30

# Kritische Dienste checken:
for svc in nvidia-powerd gamemoded ollama rygel sshd; do
    systemctl is-active "$svc" 2>/dev/null
done
```

Bei jedem Dienst: Wird er gebraucht? Wenn nein, stop + disable.

### 4. Benutzer & Zugänge

```bash

set -euo pipefail
# Benutzer mit Shell
sudo cat /etc/passwd | grep -E "/home|/bin/bash" | cut -d: -f1,3,7

# Leere Passwörter
awk -F: '($2==""){print}' /etc/shadow 2>/dev/null

# NOPASSWD in sudoers
sudo cat /etc/sudoers 2>/dev/null | grep -i NOPASSWD
sudo cat /etc/sudoers.d/* 2>/dev/null | grep -i NOPASSWD

# Passwort-Hashing (sollte yescrypt oder sha512 sein)
cat /etc/pam.d/common-password | grep pam_unix
```

### 5. Updates

```bash

set -euo pipefail
apt list --upgradable 2>/dev/null | grep -c "/"
flatpak update 2>/dev/null | grep -c "Updating\|Installing"
```

### 6. Bewertung & Doku

Jeden Fund kategorisieren:

| Farbe | Bedeutung |
|-------|-----------|
| 🟢 **✅** | Sicher / korrekt |
| 🟡 **⚠️** | Auffällig — Verbesserung möglich |
| 🔴 **❌** | Kritisch — sofort fixen |

Für jeden 🔴/🟡-Fund notieren:
- Was genau ist das Problem
- Welches Risiko besteht
- Wie es zu beheben ist (genauer Befehl)
- Ob der User zustimmen muss

## Agent-Config Security Audit

**Gegenstand:** Die laufende Hermes/Agent-Config (`~/.hermes/config.yaml`,
`~/.hermes/profiles/*/config.yaml`) gegen die Repository-Vorlage (Template) prfen.
Findet Konfig-Drift, fehlende Security-Blcke, falsche Permission-Settings,
fehlende Limits.

Dieser Audit-Typ untersucht nicht das Host-System (siehe Host-Sektionen oben),
sondern die *Agent-Konfiguration selbst* — die zweite Sicherheitsschicht.

### Wann ausfhren

- Nach Repo-Wechsel / Config-Migration
- Wenn der User "hardening", "security audit" oder "config check" sagt
- Nach Skill-Installationen (Skills knnen Config-Blcke berschreiben)
- Periodisch (monatlich) zur Erkennung von Konfig-Drift

### Phasen-Workflow (adaptiert aus GreyHack)

| Phase | Fokus | Typische Checks |
|-------|-------|-----------------|
| 0 | Backup/SecretRef | Snapshot-Alter, Secret-Backend-Existenz, Key-Rotation |
| 1 | User-Audit | Agent luft als root? ~/bin-Ownership? |
| 2 | Port-Audit | Gateway-Bind (127.0.0.1?), world-listening Services |
| 3 | Egress/Firewall | ufw aktiv? DNS fr Allowlist-Hosts? |
| 4 | Permission-Check | default: deny, write_paths, deny-lists, world-writable Files |
| 5 | Trace/Cron | Root-Cron, Git-Branch, uncommitted Changes |
| M | Modell-Limits | monthly_limit_eur, Heartbeat-Budget, Provider-Konfig |

#### Phase 0: Backup / SecretRef-Status

```bash

set -euo pipefail
# Secret-Backend (OpenClaw SecretRef oder Hermes-nativ?)
ls -la ~/.openclaw/out/ 2>/dev/null || echo "SecretRef fehlt — Hermes-native?"
ls -la ~/.hermes/auth.json 2>/dev/null

# Config-Sicherung — Alter ermitteln
SNAP=$(ls -t ~/.hermes/state-snapshots/ 2>/dev/null | head -1)
[ -n "$SNAP" ] && echo "Letzter Snapshot: $(stat -c %y ~/.hermes/state-snapshots/$SNAP | cut -d. -f1)"
BACKUP=$(ls -t ~/.hermes/config.yaml.bak.* 2>/dev/null | head -1)
[ -n "$BACKUP" ] && echo "Letztes Config-Backup: $(stat -c %Y "$BACKUP")"
```

**Threshold:** SecretRef muss existieren ODER Hermes-native mit 0600. Snapshot max 14 Tage alt.

#### Phase 1: User-Audit

```bash

set -euo pipefail
[ "$(id -u)" -eq 0 ] && echo " Agent luft als root!"
ls -ld ~/bin/ ~/bin/*.sh 2>/dev/null | grep -v "$(id -un):$(id -gn)" | head -3
```

**Threshold:** Agent uid != 0. Falls uid 0: P0-Finding, sofort stoppen.

#### Phase 2: Port-Audit (Gateway)

```bash

set -euo pipefail
# Gateway auf 127.0.0.1? (NIE 0.0.0.0)
ss -tlnp | grep 18789 | grep -v "127.0.0.1:" && echo " Gateway auf 0.0.0.0!"
# Alle world-listening Ports katalogisieren
ss -tlnp | grep "0.0.0.0:" | grep -v "127.0.0.1:" | head -10
```

**Threshold:** Gateway nur auf 127.0.0.1. World-listening-Ports dokumentiert und begrndet.

#### Phase 3: Egress / Firewall

```bash

set -euo pipefail
ufw status 2>/dev/null | grep -q "Status: aktiv" || echo " ufw inaktiv"
for host in openrouter.ai api.telegram.org github.com; do
    host "$host" >/dev/null 2>&1 || echo " DNS-Fehler: $host"
done
```

#### Phase 4: Permission-Check (DEFAULT-DENY)

**Die Kernphase.** Lese die aktuelle Config, prfe gegen Soll-Werte.

```bash

set -euo pipefail
CONFIG="$HOME/.hermes/config.yaml"
test -f "$CONFIG" || { echo " Keine Hermes-Config"; exit 1; }

python3 << 'PY'
import yaml, os, subprocess
with open(os.path.expanduser("~/.hermes/config.yaml")) as f:
    cfg = yaml.safe_load(f) or {}
findings = []
perm = cfg.get("permissions", {})
if perm.get("default") != "deny":
    findings.append(("P1", "permissions.default != deny"))
write_paths = perm.get("file", {}).get("write_paths", [])
if not write_paths:
    findings.append(("P1", "write_paths fehlt — Default-Deny fr Files nicht durchsetzbar"))
elif len(write_paths) > 6:
    findings.append(("P2", f"write_paths hat {len(write_paths)} Eintrge — zu breit"))
deny = perm.get("tools", {}).get("terminal", {}).get("deny", [])
deny_str = " ".join(deny)
if "git push* main*" not in deny_str and "main" not in deny_str:
    findings.append(("P1", "git push auf main nicht in deny"))
if "sudo" not in deny_str:
    findings.append(("P1", "sudo nicht in deny — Rechte-Eskalation"))
config_perm = oct(os.stat(os.path.expanduser("~/.hermes/config.yaml")).st_mode & 0o777)
if config_perm != "0o600":
    findings.append(("P0", f"config.yaml ist {config_perm} (sollte 600)"))
result = subprocess.run(
    ["find", os.path.expanduser("~/.hermes/"), "-type", "f", "-perm", "-o+w"],
    capture_output=True, text=True, timeout=10)
ww = [f for f in result.stdout.strip().split("\n") if f.strip()]
if ww:
    findings.append(("P0", f"{len(ww)} world-writable Dateien: {ww[0]}"))
for sev, msg in findings:
    print(f"[{sev}] {msg}")
if not findings:
    print("Alle Permission-Checks OK")
PY
```

**Threshold-Table:**

| Check | Severity bei Fail | Soll-Wert |
|-------|-------------------|-----------|
| default: deny | P1 | deny |
| write_paths definiert | P1 |  1 Pfad, < 6 |
| git push* main* in deny | P1 | substring in deny: |
| sudo* in deny | P1 | substring in deny: |
| config.yaml Perm | P0 | 0600 |
| World-writable Files | P0 | 0 Treffer |

#### Phase 5: Trace-Monitoring (Cron + Git + Prozesse)

```bash

set -euo pipefail
# Root-Cron (sollte leer sein)
crontab -l 2>/dev/null | grep -v "^#" | head -10
sudo crontab -l 2>/dev/null && echo " Root-Cron aktiv!"
# Git-Branch
cd "$REPO_DIR" 2>/dev/null && git branch --show-current
```

#### Phase M: Modell-Limits & Routing

```bash

set -euo pipefail
python3 << 'PY'
import yaml, os
with open(os.path.expanduser("~/.hermes/config.yaml")) as f:
    cfg = yaml.safe_load(f) or {}
for name, m in cfg.get("models", {}).items():
    limit = m.get("monthly_limit_eur")
    if limit is None:
        print(f"[P1] Modell '{name}': Kein monthly_limit_eur")
    elif name == "heartbeat" and limit > 5:
        print(f"[P2] Heartbeat: Limit {limit}€ — fr Watchdog zu teuer")
PY
```

### Finding-Bewertung und Aktionen

| Severity | Bedeutung | Aktion |
|----------|-----------|--------|
| **P0** | Sicherheitsverletzung | Nie auto-fixen — User fragen. Hook: Telegram-Alert |
| **P1** | Wichtige Lcke, diese Woche | Daily-Digest, dann gemeinsam fixen |
| **P2** | Nice-to-have | Log only, nchster Monats-Durchlauf |
| **OK** | Erfllt | Keine Aktion |

### Config-Gegencheck: Template vs Live

Der produktivste Schritt: laufende Config gegen Repo-Vorlage differn.

```bash

set -euo pipefail
TEMPLATE="/tmp/maxclaw-clone/config/config.yaml"  # oder angepasster Pfad
LIVE="$HOME/.hermes/config.yaml"
if [ -f "$TEMPLATE" ]; then
    python3 -c "
import yaml
with open('$TEMPLATE') as f: t = yaml.safe_load(f)
with open('$LIVE') as f: l = yaml.safe_load(f)
for section in ['permissions', 'models', 'gateway', 'automation']:
    t_s = t.get(section, {}); l_s = l.get(section, {})
    for key in t_s:
        if key not in l_s:
            print(f'[P1] Fehlt in {section}.{key}')
        elif l_s[key] != t_s[key]:
            print(f'[P2] Abweichung in {section}.{key}')
"
fi
```

### Referenzen

- `references/greyhack-security-phases.md` — Mapping der 6 GreyHack-Security-Phasen auf Linux/Hermes-Checks, mit CLI-Befehlen pro Phase
- `references/audit-example.md` — Reales Audit-Beispiel mit Befunden und Quick-Fixes von the user's Zorin OS

## Quick-Fix Cheatsheet

```bash

set -euo pipefail
# Dienst deaktivieren
sudo systemctl stop <dienst>
sudo systemctl disable <dienst>

# Dienst auf localhost beschränken (UFW deny+allow pattern)
# Blockiert ALLE externen Zugriffe, erlaubt nur localhost
sudo ufw deny <port>/tcp
sudo ufw allow from 127.0.0.1 to any port <port> proto tcp
# Vorteil: Dienst bleibt aktiv und nutzbar, aber nicht von extern erreichbar

# SSH deaktivieren (wenn nicht gebraucht)
sudo apt purge openssh-server

# Config-Berechtigungen korrigieren
chmod 600 ~/.gmail-organizer.json ~/.hermes/config.yaml
chmod 700 ~/.ssh/

# HERMES-SPEZIFISCH: Session-DB + Logs härten
chmod 600 ~/.hermes/state.db ~/.hermes/kanban.db ~/.hermes/.hermes_history
chmod 600 ~/.hermes/state.db-wal ~/.hermes/state.db-shm
chmod 600 ~/.hermes/logs/agent.log ~/.hermes/logs/errors.log
chmod 700 ~/.hermes/state-snapshots/
find ~/.hermes/state-snapshots/ -type f -exec chmod 600 {} \;
chmod 600 ~/.hermes/config.yaml.bak.* 2>/dev/null

# Request-Dumps löschen (alte API-Debug-Files, potentiell sensitiv)
find ~/.hermes/ -name 'request_dump_*.json' -delete

# Fail-Close aktivieren (Tool-Ausfall = Ablehnung, nicht Open-Bar)
hermes config set tirith_fail_open false

# DM-Policy schließen (nur bekannte User)
hermes config set telegram.dm_policy closed

# Nach Config-Änderungen: Gateway neustarten
systemctl --user restart hermes-gateway.service

# Config .env Backup vor Edits (Niemals sed -i auf .env!)
cp ~/.hermes/.env ~/.hermes/.env.pre-$(date +%s)

# Config .env aus Pre-Update-Snapshot wiederherstellen (bei Korruption)
# ls ~/.hermes/state-snapshots/ | sort | tail -1 → snapshot-dir
# cp ~/.hermes/state-snapshots/<latest>/.env ~/.hermes/.env

# Ollama Crash-Loop beenden (Port-Konflikt zwischen Snap und systemd)
# 1. Finde was auf Port 11434 läuft
ss -tlnp | grep 11434
# 2. Snap-Version läuft bereits → systemd-Version deaktivieren
sudo systemctl stop ollama && sudo systemctl disable ollama
# ODER: Snap entfernen + systemd-Version nutzen
sudo snap remove ollama
```

## Dokumentation

Nach dem Audit eine Datei `~/docs/system/security.md` schreiben mit:
- Übersicht offene Ports (nach Interface getrennt)
- Berechtigungs-Status
- Dienst-Status-Tabelle
- Quick-Wins (was wurde/wird gefixt)
- Datum

Format siehe `~/docs/system/security.md` (Beispiel vom 03.06.2026).

### Referenzen
- `references/audit-example.md` — Reales Audit-Beispiel mit Befunden und Quick-Fixes von the user's Zorin OS
