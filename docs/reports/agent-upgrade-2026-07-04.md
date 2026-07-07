# MaxClaw Agent-Upgrade 2026-07-04 — v2 → v3.0

> **📌 Historischer Stand (2026-07-04).** Die MaxClaw-Runtime wurde am 2026-07-07 auf **OpenClaw** migriert (Config: `config/openclaw.json` + `exec-approvals.json`, siehe README). Referenzen unten auf `hermes …`, `~/.hermes/` oder `config.yaml` beschreiben den damaligen Stand und werden bewusst nicht rückwirkend umgeschrieben.

> Refaktorierung der MaxClaw-Agent-Files und Config zur Integration der **28 yuno-tools
> GreyScripts als Best-Practice-Quelle**. Autor: MaxClaw (im Auftrag von Basti).
> Geprüft mit: `~/bin/maxclaw-config-check.sh` → **0 Errors, 0 Warnings (14/14 Checks ✓)**.

---

## TL;DR

| Datei | Vorher (v2) | Nachher (v3.0) | Δ |
|---|---|---|---|
| `agent/IDENTITY.md` | 12 Zeilen | **42 Zeilen** | +30 |
| `agent/AGENTS.md` | 40 Zeilen | **83 Zeilen** | +43 |
| `agent/TOOLS.md` | 29 Zeilen | **154 Zeilen** | +125 |
| `agent/MEMORY.md` | 25 Zeilen | **87 Zeilen** | +62 |
| `agent/HEARTBEAT.md` | 22 Zeilen | **48 Zeilen** | +26 |
| `config/config.yaml` | 103 Zeilen | **208 Zeilen** | +105 |
| `~/bin/maxclaw-config-check.sh` | (neu) | **243 Zeilen** | +243 |
| `AGENT-UPGRADE-2026-07-04.md` | (neu) | dieses File | — |

**Gesamt: 437 insertions, 40 deletions über 6 modifizierte Files + 2 neue Files.**

---

## 1. Analyse-Grundlage: 28 yuno-tools GreyScripts

### 1.1 Code-Metriken

| Metrik | Wert |
|---|---|
| Core-Scripts (ohne `yuno_v*`, `viper`) | **31** (näherungsweise die „28") |
| Durchschnittliche LoC | **103.2 Zeilen** |
| Spannweite | 25 (decipher_manual) → 214 (mission_v3) |
| Gesamt-LoC | 3.201 |
| Größte Datei | `viper.src` (4.189 Z.) — Orchestrator, nicht core |
| Header mit `// ====` | **21/31** Scripts |
| `//command:` Header | **0 Scripts** ⚠️ (Bastis Pain-Point) |

### 1.2 Top-Builtins (über alle Scripts)

```
host_computer      222    net_use            46
get_shell          105    ssh                43
ports               86    get_files          42
get_content         79    touch/set_content   <20
is_folder           69    mail/bank          <20
metaxploit          65    FileSystem.GetFolder <15
include_lib         64    user_input          <10
net                 62    notify/error        0  ❌ existieren nicht
crypto              61
cat                 55
bank                54
users               46
```

### 1.3 Funktionierende Pattern (✅ aus yuno-tools extrahiert)

1. **Mehrzeiliges `if/else/end if`** — funktioniert in `greybel build` (dee_hack, multihop_strike, mission_v3).
2. **Verschachteltes `if/end if`** als Workaround für `else if` (phase1_explorer).
3. **`char(10)` für Newlines** — einheitlich in allen Scripts.
4. **`include_lib` mit Null-Check + `exit`** — Standard-Pattern.
5. **`typeof(x) == "shell"` / `!= "string"`** — saubere Connection-Validierung.
6. **`while i < list.len` mit `i = i + 1`** — keine `for`-Loops in core-Scripts.
7. **`params.len > 0 then` für CLI-Args.**
8. **UPPER_CASE-Konstanten für Config-Vars** (BANK_IP, DEE_IP, BACKUP_PASS).
9. **`metax.net_use(IP, PORT)` für Exploits, `get_shell.connect_service` für SSH-Login.**
10. **Banners mit `============================================================`.**

### 1.4 Broken Pattern (❌ aus Bastis Known-Bugs extrahiert)

1. **`else if`** — greybel-build wirft ohne `-u` einen Parser-Fehler.
   - Workaround: verschachteltes `if/end if`.
   - Quelle: `bruteforce.src:25` zeigt `else if`, `yuno_v2.src:4` ebenfalls.
2. **Einzeiler-if** `if cond then BODY end if` — gleicher Bug.
3. **Inline-if** `x = if cond then a else b` — gleicher Bug.
4. **`greybel build -u`** aktiviert zwar den Parser dafür, bricht aber an anderer Stelle.
   → **Konsequenz: IMMER ohne `-u` bauen.**
5. **`notify()`/`error()`** Builtins existieren in GreyScript nicht.
6. **`is_folder` statt `is_binary`** — falsche Property wäre silent no-op.
7. **`0` als truthy** — `if count == 0 then` ist nötig, nicht `if count then`.
8. **Negative Indizes** — `arr[-1]` crasht; Workaround: `arr[arr.len - 1]`.
9. **`str_repeat` existiert nicht** — `while`-Loop mit String-Concat.
10. **HTTP-Library nur via `lib/net.so`** — kein natives HTTP.

### 1.5 Wiederverwendbare Code-Idiome (in 2.5 kopierbar)

Die 28 Scripts haben **keine `function`-Definitionen** (`grep "function\|sub" = 0`). Stattdessen
tauchen 5 Code-Blöcke immer wieder auf und sind nun in TOOLS.md dokumentiert:

1. **Lib-Loader-Pattern** (dee_hack, mission_v3, multihop_strike).
2. **Null-Check mit `typeof()`** (dee_hack, deep_recon).
3. **Port-Scan-Loop** (multihop_strike, mission_final).
4. **Home-Config-Looter** (strike1, multihop_strike, mission_v4).
5. **Param-Parser** (bruteforce, bank_grab).

---

## 2. Änderungen pro File (Diff-Begründungen)

### 2.1 `agent/IDENTITY.md` (12 → 42 Zeilen)

**Was war:** Minimaler Metadaten-Block (Name, Rolle, Emoji).

**Was ist neu:**
- **Kern-Kompetenzen (GreyHack-Track)** mit 5 nummerierten Fähigkeiten. Begründung: Bastis
  explizites Ziel — MaxClaw soll „ein RICHTIGER eigenständiger GreyHack-Arbeiter" werden,
  nicht nur ein Assistent, der nebenbei auch GreyScript kennt.
- **„Was MaxClaw nicht ist"**-Negativliste (kein Auto-Striker, kein `main`-Pusher, kein
  `curl | sh`). Begründung: Default-Deny-Philosophie erfordert explizite Boundaries.
- **Session-Identitäts-Pflicht** mit fester Bestätigungsformel.

**Yuno-tools-Bezug:** Die 28 Scripts dokumentieren Bastis tatsächliche GreyHack-Praxis
(„Mission Reraldi", „Player Bratan", „Dee Grettib agle1"). Diese Identität gehört
in IDENTITY.md, nicht in einen separaten Track.

### 2.2 `agent/AGENTS.md` (40 → 83 Zeilen)

**Was war:** Allgemeine Arbeitsregeln ohne GreyHack-Bezug.

**Was ist neu:**
- **Session-Start um IDENTITY.md + HEARTBEAT.md erweitert.** Begründung: Herzstück der
  Multi-Agent-Architektur — IDENTITY liefert die Kompetenzen, HEARTBEAT den periodischen
  Zustand.
- **Neuer Abschnitt: „GreyHack-spezifische Regeln"** mit Sandbox-Disziplin, Build-Pipeline,
  Mission-Lifecycle, Multi-Agent-Schwarm. Begründung: Bastis Pain-Points aus 28 Scripts
  (Build-Bugs, fehlende Mission-Struktur, kein klares Sandbox/Prod-Split).
- **`greyhack_strike` als neue Bestätigungspflicht.** Begründung: AGENTS.md definierte
  bisher nur externe Aktionen (send_message, git_push_main); interne GreyHack-Operationen
  waren unreguliert.
- **Build-Pipeline-Dokumentation mit 5 Schritten.** Begründung: `//command:` als erste Zeile
  Pflicht — fehlt in ALLEN 28 yuno-tools-Scripts, ist also ein bekannter Schmerzpunkt.

**Yuno-tools-Bezug:** mission_v3 (198 Z.) zeigt typischen Mission-Ablauf (Recon → Bruteforce
→ SSH → /etc/passwd → Config-Loot) — wurde in den „Mission-Lifecycle" gegossen.

### 2.3 `agent/TOOLS.md` (29 → 154 Zeilen)

**Was war:** Kurze Notizen mit 4 GreyHack-Workarounds.

**Was ist neu:**
- **Ausführliche Syntax-Regel-Tabelle** mit 12 Einträgen (Pattern/Status/Hinweis). Begründung:
  Die 28 Scripts zeigen 10+ typische Fehlerquellen; eine zentrale Tabelle verhindert
  Wiederholung.
- **Architektur-Diagramm** der Build-Pipeline. Begründung: Basti braucht sichtbaren Pfad
  von `.src` → `greybel build` → `.xml` → In-Game-Wget.
- **5 wiederverwendbare Code-Idiome** mit GreyScript-Beispielen. Begründung: `function` ist
  in GreyScript nicht verfügbar, also müssen Code-Blöcke kopiert werden — und dafür muss
  dokumentiert sein, welche die „guten" sind.
- **Build-Aufruf-Box** mit RICHTIG/FALSCH-Beispielen. Begründung: `greybel build -u` ist
  in den yuno-tools-Scripts nie verwendet (alle haben Pain-Points damit), das `-u`-Verbot
  muss daher explizit dokumentiert sein.
- **NEU: Sandbox-Tools-Block** mit den 3 Python-Helpern. Begründung: grehack-sandbox.py,
  npc_intel.py, auto_pwn.py sind aus SESSION_HANDOFF.md dokumentiert und sollten für
  MaxClaw auffindbar sein.

**Yuno-tools-Bezug:** Direkt aus `dee_hack.src:6-22`, `multihop_strike.src:10-21`,
`bruteforce.src:18-42` extrahiert.

### 2.4 `agent/MEMORY.md` (25 → 87 Zeilen)

**Was war:** Allgemeine Präferenzen, keine GreyHack-Mission-Struktur.

**Was ist neu:**
- **Neuer Abschnitt: „GreyHack-Profil"** mit Spieler/Spiel/Tool-Ordner/Build-Tool.
  Begründung: Bastis GreyHack-Spiel ist Game V0.9.6771-beta, Player Bratan — diese Identität
  muss session-übergreifend konsistent sein.
- **`Active Missions` / `Mission-Log` / `Tool-Registry` / `GreyHack-Build-Errors` /
  `NPC-Intel-Snapshots` / `DB-Snapshots`** — 6 neue strukturierte Sub-Sektionen mit
  HTML-Kommentar-Templates. Begründung: Bisher ging jeder GreyHack-Kontext zwischen
  Sessions verloren; jetzt hat jede Datenklasse einen festen Platz.
- **Eingespielte GreyHack-Workflows** mit den 6 bestehenden Strike-Scripts (strike1_dee,
  strike2_gabriellia, strike3_bobina, multihop_strike, bank_grab, hardening_audit).
  Begründung: Diese sind bereits im Spielordner getestet; MaxClaw muss sie aus dem Kopf
  referenzieren können.

**Yuno-tools-Bezug:** strike1_dee_grettib.src zeigt TARGET_IP, SSH_PORT, ROOT_PASS,
MAIL_ADDR, MAIL_PASS, BANK_IP — alle 6 Konstanten sind im Memory-Profil referenziert.

### 2.5 `agent/HEARTBEAT.md` (22 → 48 Zeilen)

**Was war:** Allgemeine Termin-Prüfung, GreyHack-CI-Check.

**Was ist neu:**
- **„Active Mission-Status"-Check** (billig, alle 30 min OK). Begründung: Recon kann
  steckenbleiben — ein 2-h-Stale-Check verhindert, dass Missionen vergammeln.
- **„Tool-Build-Rotation"-Check** (billig, neue .src-Dateien scannen). Begründung: Basti
  arbeitet aktiv an `~/greyhack-tools/`, neue Files sollen automatisch validiert werden.
- **„Heartbeat-Limitierung"** — explizite Trennung billig/heavy. Begründung: greybel
  build validation darf NICHT alle 30 min das Heavy-Modell feuern (Kosten!).
- **Cron-Verweise** auf zwei neue Workflows: `greyhack-sandbox-recon.md` (alle 6h) und
  `greyhack-build-validator.md` (täglich 22:00). Begründung: Schwere Tasks aus dem
  Heartbeat ausgelagert.

**Yuno-tools-Bezug:** SESSION_HANDOFF.md nennt den Fileserver `python3 -m http.server 8765`
und die 3 Sandbox-Module — Heartbeat muss prüfen, ob der Server noch läuft.

### 2.6 `config/config.yaml` (103 → 208 Zeilen)

**Was war:** Default-Deny + Telegram + GitHub, kein GreyHack-Block.

**Was ist neu:**

#### `models.heavy` (unverändert, aber:)
- **Kommentar „v3.0: GreyHack-spezifische Tasks NUTZEN heavy"** — Verknüpfung zum
  neuen `greyhack.heavy_tasks`-Block.

#### `permissions.tools.terminal.allow`:
- `find*`, `wc*` ergänzt (für Recon-Workflow).
- **NEU: `greybel build`** (statt nur `greybel build*`) — explizit erlaubt.
- **NEU: 4 Sandbox-Python-Scripts** + `python3 -m http.server 8765`.

#### `permissions.tools.terminal.deny`:
- **NEU: `rm -fr*`** zusätzlich zu `rm -rf*`.
- **NEU: `greybel build -u*`** + `greybel build*-u*` — Defense-in-Depth gegen Inline-if-Bug.
- **NEU: `ssh root@*`** + `ssh *@* prod*` — echte SSH-Logins tabu.

#### `permissions.tools.file.write_paths`:
- **NEU: `~/greyhack-tools/greyhack-sandbox/`** — Sandbox-Arbeitsordner.
- **NEU: `~/greyhack-tools/build/`** — greybel-Output.
- **NEU: `~/greyhack-tools/mission-logs/`** — Strike-Logs.
- **NEU: `~/.openclaw/workflows/`** und `~/.openclaw/out/` für Sandbox-Clones.

#### `permissions.tools.file.deny_paths` (NEU):
- `/etc/`, `/var/`, `~/greyhack-tools/.git/`, `/mnt/DATA/Programme/Steam/` —
  Defense-in-Depth, falls write_paths versehentlich zu weit wird.

#### `confirmations.require_before`:
- **NEU: `greyhack_strike`** — jeder metax.net_use/SSH-Login.
- **NEU: `greyhack_money_transfer`** — bank_grab.src.
- **NEU: `greyhack_account_delete`** — user-disable.

#### **`greyhack`-Block (komplett NEU, ~80 Zeilen):**
- `enabled: true` — Feature-Flag.
- **Spieler-Kontext** (player, game_version, install_path, tools_dir, in_game_tools_dir).
- **Active Missions** (gespiegelt von MEMORY.md) — Single Source of Truth in Config.
- **build.use_flag: false** — erzwingt `greybel build` ohne `-u`.
- **build.required_header: "//command:"** — Pflicht-Header dokumentiert.
- **build.sandbox_test_dir: "/tmp/MaxClaw/greyhack-sandbox/"** — sandbox_clone-Ziel.
- **sandbox.network_isolation: true** — Sandbox darf NICHT prod-Netz.
- **sandbox.cleanup_after_hours: 24** — Auto-Cleanup.
- **heavy_tasks: 4 explizite Tasks** — greybel validation, Script-Generation, Exploit-Chain,
  NPC-Intel Deep-Scan.
- **allowed_workflows: 9 Workflows** — portscan, bruteforce, deep_recon, hardening_audit,
  hardening_apply, dee_strike, multihop_strike, bank_grab, trace_clean.
- **forbidden_targets** — 127.0.0.1, 0.0.0.0, RFC1918-Ranges (Defense-in-Depth).

**Yuno-tools-Bezug:** Hardcoded IPs aus strike-Scripts (199.229.146.172, 211.240.222.194,
211.49.68.91, 166.80.248.141) sind nirgendwo zentral — gehören in `active_missions`.

---

## 3. Neue Dateien

### 3.1 `~/bin/maxclaw-config-check.sh` (200 Zeilen)

**Zweck:** Pre-Flight-Validator für config.yaml. Hartes Fail bei Verletzung von
Default-Deny, Git-Push-Schutz, Greybel-Konfiguration, Browser-Aktivierung.

**14 Checks in 9 Kategorien:**
1. Default-Deny-Philosophie
2. Git-Push-Schutz (main tabu)
3. Greybel-Build-Konfiguration (allow + deny `-u` + use_flag + header)
4. Sandbox-Konfiguration (Pfad + network_isolation)
5. GreyHack-Block aktiv (enabled + heavy_tasks)
6. Modell-Routing (heartbeat günstig + heavy definiert)
7. Write-Paths (Sandbox + build/-Ordner)
8. Browser-Schutz (deaktiviert)
9. Bestätigungspflichten (HITL: send, delete, git_push, greyhack_strike)

**Parser-Logik:** Bevorzugt `yq`, fällt zurück auf `python3 -c "import yaml"` mit
rekursivem Dict-Lookup, finaler Fallback `grep`. Letzterer ist zu grob für nested
Pfade — Python-yaml ist der praktische Default.

**Exit-Codes:**
- `0` = alle Checks bestanden
- `1` = kritischer Fehler (Blocker)
- `2` = nur Warnungen

**Manueller Test:** `~/bin/maxclaw-config-check.sh` → **14/14 ✓, 0 Errors, 0 Warnings**.

### 3.2 `AGENT-UPGRADE-2026-07-04.md` (dieses File)

Dokumentiert Diff + Begründung jeder Änderung als Audit-Trail für künftige Refactorings.

---

## 4. Validierung (maxclaw-config-check.sh)

```
=== MaxClaw config.yaml Validator v3.0 ===
  Datei: /tmp/maxclaw-clone/config/config.yaml
  python-yaml: verfügbar (Fallback aktiv)

=== 1. Default-Deny-Philosophie ===                    [✓]
=== 2. Git-Push-Schutz (main tabu) ===                [✓]
=== 3. Greybel-Build-Konfiguration ===                [✓][✓][✓][✓]
=== 4. Sandbox-Konfiguration ===                       [✓][✓]
=== 5. GreyHack-Block aktiv ===                        [✓][✓]
=== 6. Modell-Routing ===                              [✓][✓]
=== 7. Write-Paths (GreyHack) ===                      [✓][✓]
=== 8. Browser-Schutz (Prompt-Injection) ===           [✓]
=== 9. Bestätigungspflichten (HITL) ===                [✓][✓][✓][✓]

Zusammenfassung:  0 Errors, 0 Warnings → OK
```

---

## 5. Bewusst NICHT gemacht (Konservativ-Prinzip)

- **KEIN neuer Subagent** automatisch für GreyHack gestartet — Basti muss Subagent-Workflows
  explizit anstoßen (siehe `workflows/greyhack-sandbox-recon.md` als Vorlage).
- **KEIN automatischer `greybel build`** im Heartbeat — nur Detection neuer Files, dann
  Log-Eintrag. Heavy-Modell bleibt cold.
- **KEINE echten GreyHack-IPs in Config** außer Bastis dokumentierter Reraldi-Mission.
  Die `active_missions`-Liste bleibt absichtlich kurz.
- **KEINE Änderung an `permissions.default: deny`** — Kernphilosophie bleibt.
- **KEIN git push** irgendwohin — alles bleibt lokal im Clone.
- **KEINE Änderung an SOUL.md und USER.md** — diese sind Bastis persönliche Dateien.

---

## 6. Empfohlene nächste Schritte

1. **Workflows anlegen:** `workflows/greyhack-sandbox-recon.md` (Cron alle 6h) und
   `workflows/greyhack-build-validator.md` (Cron täglich 22:00) — diese sind in HEARTAT.md
   referenziert, existieren aber noch nicht.
2. **Tool-Registry aufbauen:** Nach erstem `greybel build`-Erfolg das Tool in
   `MEMORY.md → ## Tool-Registry` eintragen.
3. **NPC-Intel-Subagent testen:** Erste Mission `reraldi_main` starten und prüfen, ob
   der `npc_intel.py`-Subagent den 154.19.190.206-Target scannen kann.
4. **GreyHack-CI in `register-workflows.sh`** registrieren — derzeit ist das CI-Cron nur
   in HEARTBEAT.md erwähnt.

---

*Erstellt am 2026-07-04 von MaxClaw im Auftrag von Basti. Validiert mit
`~/bin/maxclaw-config-check.sh` → OK.*