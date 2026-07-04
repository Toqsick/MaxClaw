# MaxClaw — Security Policies (Stand 2026-07-04)

> **Leitlinie:** *Defensive by design.* Basti hat ein lokales Linux-System, will nicht durch
> seinen eigenen Agent gestört werden. Default-Deny, Least Privilege, Audit-trail bei jeder
> sicherheitsrelevanten Aktion.

Diese Datei ist die **verbindliche Policy** für MaxClaw auf Bastis Host. Sie wird ergänzend zu
[`config/config.yaml`](../config/config.yaml) und [`docs/07-security.md`](../docs/07-security.md)
gelebt. Bei Konflikt gilt die **restriktivere** Auslegung.

---

## 1. Goldene Regeln (nicht verhandelbar)

| # | Regel | Begründung |
|---|-------|------------|
| G1 | **Default-Deny** — alles Verboten ist Default; jede Erlaubnis muss explizit sein. | Sicherer als „alles erlaubt, gefährliches sperren". |
| G2 | **Read-only by default** — Audits schreiben Reports, niemals Fixes. Fixes nur nach Bastis Freigabe. | Verhindert versehentliche Schäden durch autonomes Handeln. |
| G3 | **Keine Klartext-Secrets** — alles via SecretRef (`~/.openclaw/out/`), nie in YAML, nie in Git. | Git-History vergisst nicht. |
| G4 | **`main` ist tabu** ohne explizite Freigabe — `develop` / `feature` ok. | `main` ist Bastis Wahrheit. |
| G5 | **Browser-Tool aus** (Prompt-Injection-Risiko) — `web_search` reicht für die meisten Tasks. | 36 % der ClawHub-Skills enthalten PI (Claw-Havoc-Kampagne). |
| G6 | **Cron niemals als root** — ausschließlich systemd-user-Timer oder User-Crontab. | Local-Prinzip, kein Blast-Radius über den User-Account hinaus. |

---

## 2. Aktionen — was ist erlaubt, was verboten?

### 2.1 Dateisystem

| Aktion | Status | Bedingung / Begründung |
|--------|--------|------------------------|
| Lesen in `~/greyhack-tools/`, `~/docs/`, `~/.openclaw/`, `~/.hermes/` | ✅ erlaubt | Primäre Arbeitsverzeichnisse. |
| **Schreiben** nur in den deklarierten `write_paths` der config.yaml | ✅ erlaubt | Default-Deny-Pfad. |
| Schreiben außerhalb `write_paths` | ❌ verboten | Schutz vor Datenlecks / Wildwuchs. |
| Löschen außerhalb `~/greyhack-tools/build/` und `~/.cache/` | ⚠️ **Bestätigungspflicht** | AGENTS.md §Bestätigungspflicht. |
| Welt-beschreibbare Files (`chmod 777`) anlegen | ❌ verboten | Klassisches Linux-Sicherheits-No-Go. |
| Symlinks auf `/etc`, `~/.ssh`, `~/.gnupg` anlegen | ❌ verboten | Privater Schlüssel-Bereich. |
| Schreibzugriff auf `~/bin/` ohne Listing in der Audit-Liste | ⚠️ **Bestätigungspflicht** | Persistenter Code-Path; vor jedem Schreiben Review. |

### 2.2 Terminal / Shell

| Pattern | Status | Begründung |
|---------|--------|------------|
| `git status`, `git diff`, `git log`, `git add`, `git commit` (auf feature/develop) | ✅ erlaubt | Tägliche Arbeit. |
| `greybel build` (ohne `-u`) | ✅ erlaubt | Bekannter Workaround, dokumentiert in TOOLS.md. |
| `greybel build -u` | ❌ verboten | Inkompatibel mit unseren Tools (Mehrzeilen-if nötig). |
| `rm -rf *` | ❌ verboten | Klassischer Killer-Pattern. |
| `sudo *` | ❌ verboten | Agent braucht keinen Root; Rechte-Eskalation unterbinden. |
| `git push * main *` / `git push origin main` | ❌ verboten (Default), ⚠️ **Bestätigungspflicht** (Ausnahme) | siehe G4. |
| `curl * | sh` / `wget * | bash` | ❌ verboten | Blind-Pipe-to-Shell = Hintertür-Standard. |
| `dd of=/dev/sd*`, `mkfs.*` | ❌ verboten | Datenträger-Zerstörung. |
| `chmod -R 777 *` | ❌ verboten | Welt-Schreibbar = offene Tür. |
| `systemctl disable` / `systemctl stop` (auf System-Services) | ⚠️ **Bestätigungspflicht** | Wir deaktivieren nichts ohne Bastis OK — auch nicht „nur lokal". |

### 2.3 Netzwerk

| Endpoint | Status | Begründung |
|----------|--------|------------|
| OpenRouter-API (`openrouter.ai`) | ✅ erlaubt | Modell-Routing. |
| `api.telegram.org` | ✅ erlaubt | Primärer Rückkanal zu Basti. |
| `api.github.com` | ✅ erlaubt | `gh`-Workflows. |
| **Beliebige andere HTTPS-Outbound** | ⚠️ **Bestätigungspflicht** (Default-Deny) | Vermeidet Exfiltration. |
| **Beliebiger HTTP (Port 80)** | ❌ verboten | Klartext, kein TLS. |
| Eingehende Connections (Gateway) | ❌ verboten (nur `127.0.0.1:18789`) | Niemals `0.0.0.0`. |

### 2.4 Secrets-Handling

| Pattern | Status | Begründung |
|---------|--------|------------|
| SecretRef-Backend nutzen (`~/.openclaw/out/`, 0700) | ✅ erlaubt (Pflicht) | Verschlüsselte Persistenz. |
| Secret in `config.yaml`, `*.yaml`, `*.json` committen | ❌ verboten | `.gitignore` blockt; trotzdem Pre-Commit-Hook sinnvoll. |
| Secret in `agent/MEMORY.md` notieren | ❌ verboten | Memory ist exportierbar (Claw-Sync, Backups). |
| Secret in Telegram-Nachricht oder Tool-Output | ❌ verboten | Kein Token-Leak in Chats. |
| Secret aus `auth.json` in einer Antwort zitieren | ❌ verboten | Sensible Felder müssen geredacted werden. |

### 2.5 Git / GitHub

| Aktion | Status |
|--------|--------|
| `git add` + `git commit` auf `develop`/`feature/*` | ✅ |
| PR erstellen mit `gh pr create` | ✅ |
| `gh pr merge` auf eigenen feature-Branches | ⚠️ Bestätigung (CI muss grün sein) |
| `gh pr merge` auf `main` | ❌ verboten |
| Push auf `main` (egal ob `git push` oder `gh`) | ❌ verboten (Default), Bestätigung als Ausnahme |
| Force-Push (`-f`, `--force`) | ❌ verboten |
| `gh repo delete` | ❌ verboten |
| Issue/PR-Kommentare schreiben | ⚠️ Bestätigung (Reputation) |

---

## 3. Skills — wer darf was?

Skill-Berechtigungen sind **separat** von den globalen Permissions. Ein Skill kann nur Tools
verwenden, die er explizit zugewiesen bekommt.

| Skill | Erlaubte Tools | Verboten | Begründung |
|-------|----------------|----------|------------|
| `greyhack` | read-only fs, `greybel build` (ohne `-u`), terminal.allow-Liste | write_paths außerhalb `~/greyhack-tools/` | Read-only-Research + Build-Pipeline. |
| `greyhack-sandbox` | Sandbox-Pfad `~/greyhack-tools/build/` schreiben, alles read | Netzwerk aus, kein Git push | Isolierte Test-Umgebung. |
| `greyscript-compiler-debugging` | read-only, terminal | write | Diagnose, kein Patch. |
| `github-ops` | `gh` (read), Telegram (Comment schreiben mit Bestätigung) | `gh repo delete`, force-push, main-merge | PR-Monitor, sanft. |
| `maxclaw-session-manager` | filesystem (eigener Bereich `~/.openclaw/sessions/`) | write außerhalb | Session-Verwaltung. |
| `telegram-notifier` | nur send_message | read_channel_messages ohne Anlass | Nur Pings. |
| `project-doc-sync` | `~/docs/system/` schreiben | globale write_paths | Eigener Bereich. |
| `knowledge-distiller` | read-only | write_paths default-Deny | Nur-Extraktion. |
| `sandbox-snapshot` | read-only + Snapshot-Ordner | System-Pfade | Eigenes Temp-Verzeichnis. |
| `sqlite-reader` | read-only | write auf DBs | Nur Queries. |
| `bash-script-builder` | `~/bin/` schreiben (mit Audit-Trail) | systemweite Pfade | Bewusst, mit Log. |

**Wildcards sind tabu.** Kein Skill darf „alle Tools" oder „alle Pfade" deklarieren — Ausnahmen
müssen explizit gelistet sein.

---

## 4. Cron-Approval-Modus

| Modus | Verhalten | Wann? |
|-------|-----------|-------|
| `safe` (Default) | Alle Cron-Jobs laufen **als User bratan** via systemd-user-Timer. Jeder Job muss vor dem ersten Lauf von Basti in `cron-jobs.md` abgehakt sein. | Produktion / Live-System. |
| `smart` (opt-in) | Häufige Watchdog-Jobs (z. B. `greyhack-ci-watch`) dürfen selbst Fehleralarme schicken; ein „OK"-Run ist silent. Andere Jobs bleiben `safe`. | Reine Watchdog-Workflows. |
| `yolo` | **Nicht verfügbar.** Nicht implementiert, nicht geplant. | — |

**Watchdog-Konvention:** Solange ein Cron-Job nur seinen eigenen Bereich (Build-Status,
GitHub-Polling) prüft und nur bei **Fehler** meldet, gilt `smart`. Sobald er schreibt,
sendet oder löscht → `safe`.

---

## 5. Network-Isolation (Default)

Ausgehende Verbindungen sind **nur erlaubt** für:

- `openrouter.ai` (Modell-API)
- `api.telegram.org` (Basti-Benachrichtigungen)
- `api.github.com` + `github.com` (gh CLI, Repo-Monitoring)
- `raw.githubusercontent.com` (Skill-Updates via vertrauenswürdige Quellen)

**Alles andere** wird auf Firewall-Ebene (ufw / nftables) geblockt. Eine Whitelist-Erweiterung
erfordert Bastis explizite Freigabe + Eintrag in `hardening_audit_maxclaw.yaml` unter
`network.allowlist`.

Eingehend: ausschließlich Loopback. Das Gateway darf **niemals** auf `0.0.0.0` binden.

---

## 6. Audit & Monitoring

| Ereignis | Aktion |
|----------|--------|
| Cron-Job läuft | Log nach `~/logs/maxclaw-cron.log`. |
| `write_paths` verletzt | Sofortiger Stop + Telegram-Alert an Basti. |
| Geheimer String in Config erkannt (Pre-Commit-Hook) | Block Commit. |
| `git push` auf `main` versucht | Hook blockiert; Telegram-Warnung. |
| `sudo`-Versuch | Block + Audit-Log-Eintrag. |
| Unbekannter Skill installiert | Telegram-Warnung an Basti. |

`~/bin/maxclaw-security-audit.sh` prüft **täglich** alle oben genannten Punkte und schreibt
einen JSON-Report nach `~/logs/maxclaw-security-audit-LAST.json`. Bei P0-Befund: sofortiger
Telegram-Alert via Hermes-Gateway.

---

## 7. Schlussbestimmung

Diese Policy ist nicht „alles, was MaxClaw tun darf", sondern „alles, was MaxClaw tun darf
**ohne zu fragen**". Für alles, was nicht hier gelistet ist: **fragen** — am besten per
Telegram mit 2–4 konkreten Optionen, wie in AGENTS.md vorgeschrieben.

Bei P0-Funden (siehe `security-audit-2026-07-04.md`) wartet MaxClaw auf Bastis Entscheidung,
**bevor** er Änderungen anwendet.