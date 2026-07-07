# Key & Secret-Rotation — MaxClaw

> **Prinzip:** Gehe davon aus, dass **alles**, was MaxClaw sehen kann, theoretisch leaken kann
> (Logs, Memory, Screenshots, Telegram-Cache). Jeder Secret hat einen Lebenszyklus, ein
> Eigentümer, ein Rotationsintervall und eine Notfall-Rotation.

---

## 1. Inventar

| # | Secret | Wo gespeichert | Zweck | Eigentümer |
|---|--------|----------------|-------|------------|
| S1 | `OPENROUTER_API_KEY` | `~/.openclaw/out/openrouter.key` (SecretRef) | Modell-API | Basti |
| S2 | `TELEGRAM_BOT_TOKEN` (`OlympAgentBot`) | `~/.openclaw/out/telegram.key` | Telegram-Chat | Basti |
| S3 | `TELEGRAM_CHAT_ID` (`7222661188`) | SecretRef (low-sensitivity) | Zieladresse | Basti |
| S4 | `GH_TOKEN` (für `gh` CLI, Toqsick-Scopes) | `~/.config/gh/hosts.yml` | GitHub-Workflows | Basti |
| S5 | `MAXCLAW_GATEWAY_TOKEN` | `~/.openclaw/out/gateway.token` | Loopback-Gateway-Auth | Basti |
| S6 | `OPENCLAW_AUTH` (auth.profiles) | `openclaw secrets`-Store | OpenClaw-Provider-Auth | Basti |
| S7 | `YUNO_CLEANER_TELEGRAM_TOKEN` | crontab-Env (siehe Hinweis) | Yuno-Cleaner-Auto-Scan | Basti |
| S8 | `OPENCLAW_GH_API_TOKEN` | crontab-Env | openclaw-gh-api-server | Basti |

---

## 2. Rotations-Intervalle

| Secret | Intervall | Begründung |
|--------|-----------|------------|
| S1 OpenRouter | **alle 90 Tage** | Externe API, breite Blast-Radius-Folge. |
| S2 Telegram-Bot | **alle 180 Tage** + **sofort** bei Verdacht. | Bot hat Write auf Bastis DM. |
| S4 gh-Token | **alle 90 Tage** (gerne PAT-Äquivalent) | Repo-Schreibrechte, force-push möglich. |
| S5 Gateway-Token | **alle 180 Tage** | Nur loopback, geringeres Risiko. |
| S6 OpenClaw-auth | **alle 180 Tage** oder bei Profil-Wechsel. | Provider-übergreifend. |
| S7, S8 (crontab) | **alle 365 Tage** | Eingeschränkte Rechte, längere Zyklen ok. |

**Notfall-Rotation: SOFORT** wenn

- Secret in Git, Log, Memory oder Telegram-Chat auftaucht.
- Verdacht auf Kompromittierung (z. B. `ps` zeigt unbekannte Prozesse mit Zugriff).
- Audit meldet P0-Fund unter `phase_4.no_world_readable_secrets`.
- Skill-Installation mit ungeklärter Herkunft.

---

## 3. Rotations-Prozedur (Schritt-für-Schritt)

### 3.1 OpenRouter-Key (S1)

```bash
# 1) Im OpenRouter-Dashboard neuen Key generieren.
# 2) Lokal ersetzen — niemals in openclaw.json eintragen!
openclaw secrets set OPENROUTER_API_KEY <NEUER_KEY>
# 3) Test: ein billiger Modell-Call
openclaw --model heartbeat "Ping?"
# 4) Alten Key im Dashboard widerrufen.
# 5) In MEMORY.md das Rotations-Datum notieren.
```

### 3.2 Telegram-Bot-Token (S2)

```bash
# 1) In BotFather: /revoke → neuen Token holen.
# 2) Lokal ersetzen
openclaw secrets set TELEGRAM_BOT_TOKEN <NEUER_TOKEN>
# 3) Test-Ping an Basti selbst.
# 4) Alten Token ist ungültig (BotFather hat ihn verworfen).
```

### 3.3 GitHub-Token (S4)

```bash
# 1) Auf github.com/settings/tokens alten Token widerrufen, neuen generieren.
# 2) Scopes minimal: repo, workflow, read:org, gist (wie bisher).
# 3) gh auth login --with-token < <(echo $NEUER_TOKEN)
# 4) Test: gh auth status
```

### 3.4 Gateway-Token (S5)

```bash
# 1) OpenClaw-nativ rotieren (erzeugt + setzt neuen Token):
openclaw token:rotate --force --length 64
# 2) Gateway-Auth bleibt Pflicht (gateway.bind = 127.0.0.1).
# 3) Service-Restart: systemctl --user restart openclaw
# 4) Clients (Telegram, Browser-Plugin) mit neuem Token versorgen.
```

---

## 4. Wo NIEMALS Secrets landen dürfen

| Ort | Warum verboten |
|-----|----------------|
| `config/openclaw.json`, `config/exec-approvals.json` | Wird committed, taucht in `git log` auf. |
| `agent/MEMORY.md`, `agent/MEMORY.local.md` | Persistenter Kontext, exportierbar. |
| `agent/daily/*.md` | Daily-Notes werden langfristig aufbewahrt. |
| Telegram-Chat (auch Privat-DM) | Kein Token in Klartext chatten. |
| `.env`-Dateien im Repo | Selbst mit `.gitignore` riskant — Repo-Klone. |
| Logs (`*.log`, `~/logs/`) | Werden gerne geteilt / analysiert. |
| Tool-Outputs (`cat auth.json`) | Niemals ausgeben — redacted. |

**Grep-Schutz** vor jedem Commit:

```bash
git diff --cached | grep -E "(token|key|pass|secret|password|api_key).*=.*['\"][^'\"]+['\"]"
# Treffer → abbrechen, Secret auslagern, neu committen.
```

---

## 5. Backup der Secrets

| Secret-Backend | Pfad | Backup-Strategie |
|----------------|------|------------------|
| SecretRef | `~/.openclaw/out/` | Verschlüsselt mit `pass` (GPG) oder `age`. Backup nach `~/backups/secrets-<datum>.tar.gpg`. |
| gh-CLI | `~/.config/gh/hosts.yml` | Manuell backuppen (Inhalt ist nicht katastrophal, aber Token schon). |
| OpenClaw-auth | `openclaw secrets`-Store (0600) | Backup vor jeder Profil-Änderung. |

**Notfall-Recovery:** `~/.openclaw/out/` ist das einzige Source-of-Truth. Geht es verloren,
müssen alle Secrets bei den jeweiligen Anbietern regeneriert werden.

---

## 6. Audit-Trail

Jede Rotation erzeugt einen Eintrag:

| Feld | Beispiel |
|------|----------|
| Datum | 2026-07-04 |
| Secret-ID | S1 (OpenRouter) |
| Alte Key-ID (letzte 4) | `…a3f1` |
| Neue Key-ID (letzte 4) | `…9d2e` |
| Grund | scheduled / verdacht / kompromittiert |
| Bestätigt durch | Basti |

Datei: `~/.openclaw/rotation-log.md` (nicht im Repo, 0600).

---

## 7. Eskalations-Pfad bei Verdacht

1. **Sofort:** betroffenes Secret beim Anbieter widerrufen (Notfall-Rotation).
2. **Audit:** `~/bin/maxclaw-security-audit.sh` manuell triggern, JSON-Report prüfen.
3. **Telegram-Alert:** P0 an Basti: *„Secret S2 kompromittiert, neu erzeugt. Letzte Aktivität: …"*
4. **Repo-Scan:** `git log -p` + `grep` nach Resten des alten Secrets.
5. **Memory-Cleanup:** `MEMORY.md` und `daily/*.md` nach versehentlichem Speichern durchsuchen.
6. **Post-mortem:** Was ist passiert? Wie kam der Secret raus? Welche Policy verhindert es beim nächsten Mal?

---

## 8. MaxClaw-spezifische Notizen

- **Heartbeats** laufen alle 30 min → nicht jeder Run darf ein Secret anfassen.
- **Watchdog-Cron-Jobs** (GreyHack-CI, GitHub-Monitor) brauchen **keinen** Schreibzugriff auf
  SecretRef. Wenn doch: Bug, sofort melden.
- **Subagenten** dürfen Secrets nur lesen, **nie** kopieren oder ausgeben.
- **Tool `memory_search` / `session_search`**: niemals Secret-bewusst durchsuchen und das
  Ergebnis zitieren — nur redacted.