# MEMORY.md — Langzeitgedächtnis (v3.0)

> Hier speichert MaxClaw dauerhaft Wichtiges: Präferenzen, wiederkehrende Fakten, zentrale
> Entscheidungen. Ziel: nicht immer wieder dasselbe fragen müssen. Kompakt & hochsignalhaltig
> halten — jeder Token wird bei *jeder* Nachricht mitbezahlt.

## Über Basti (Kurzform, Details in USER.md)

- Deutsch, Europe/Berlin, lernt by doing, will lauffähigen Code + Kontext.
- Entscheidungen als Auswahloptionen. Rückfragen → Telegram-DM `telegram:7222661188`.
- Kostenbewusst: erst kostenlos/lokal.

## Environment

- Lokaler Ubuntu-24.04-Desktop (NVIDIA RTX 5060, Docker) + GCP VM (Ubuntu/Xubuntu).
- gh CLI = Account `Toqsick`.

## Konventionen

- System-Docs nach jedem relevanten Task (`~/docs/system/`, Markdown, deutsch).
- Security-Audits read-only → Report → Fix nur nach Freigabe.
- `main` tabu ohne Info/Tests/Freigabe.

## Zentrale Entscheidungen

- MaxClaw läuft isoliert (Docker/VPS), nicht direkt aufs OS. Default-Deny in config.yaml.
- Multi-Agent-Orchestrierung ist das eigentliche Lernziel (GreyHack = Testlabor).

## GreyHack-Profil (NEU v3.0)

### Spieler & Spiel

- **Player:** Bratan
- **Spiel-Version:** Grey Hack V0.9.6771-beta (Steam Native Linux)
- **Tool-Ordner:** `/mnt/DATA/Programme/Steam/steamapps/common/Grey Hack/yuno-tools/`
- **Build-Tool:** `greybel build` (ohne `-u` — siehe TOOLS.md)
- **Lokales Repo:** `~/greyhack-tools/` (siehe TOOLS.md-Pipeline)

### Active Missions

<!-- Format: - **<mission_id>** — <ziel-IP> — <NPC/Kontakt> — <status: recon|strike|done|failed> — <nächster Schritt> -->

- **reraldi_main** — `154.19.190.206` — `Reraldi@adahidomev.net` — `recon` — NPC-Intel-Subagent starten

### Mission-Log (abgeschlossen)

<!-- Format: - **<mission_id>** — <yyyy-mm-dd> — <ergebnis> — <loot/notiz> -->

_(noch leer — nach erster abgeschlossener Mission eintragen)_

### Tool-Registry (gebaut + getestet)

<!-- Format: - **<tool_name>** — <pfad/greybel-status> — <zweck> — <letzter build: yyyy-mm-dd> -->

_(wird automatisch vom Sandbox-Build-Workflow befüllt — siehe `~/.openclaw/workflows/greyhack-tool-registry.md`)_

### GreyHack-Build-Errors (Lessons Learned)

<!-- Format: - **<yyyy-mm-dd>** — `<fehler-pattern>` — <fix> — <betroffenes script> -->

- **2026-07-04** — `greybel build -u` mit Inline-if `x = if cond then a else b` — `ohne -u bauen + mehrzeilig` — `(mehrere)`

### NPC-Intel-Snapshots

<!-- Format: - **<ip>:<port>** — <hostname/user> — <schwachstelle> — <hash/decipher-result> -->

_(vom `npc_intel.py`-Subagent befüllt)_

### DB-Snapshots (Sandbox-Inventar)

<!-- Format: - **<yyyy-mm-dd>** — <host-ip> — <user-count> — <offene ports> — <kritische files> -->

_(vom `auto_pwn.py`-Subagent befüllt)_

## Eingespielte GreyHack-Workflows (Verweise)

- **Port-Scan:** `~/greyhack-tools/portscan_adv.src` (multihop_strike-Pattern)
- **Bruteforce:** `~/greyhack-tools/bruteforce.src` (param-parser + pool-gen)
- **Decipher:** `~/greyhack-tools/decipher_pwd.src` (crypto.so wrapper)
- **Hardening-Audit:** `~/greyhack-tools/hardening_audit.src` (read-only, sicher)
- **Strike #1 (Dee Grettib):** `~/greyhack-tools/strike1_dee_grettib.src` — `199.229.146.172:22` — PW: `agle1`
- **Strike #2 (Gabriellia):** `~/greyhack-tools/strike2_gabriellia_ingoody.src` — `211.240.222.194`
- **Strike #3 (Bobina Emmer):** `~/greyhack-tools/strike3_bobina_emmer.src` — `211.49.68.91` — PW: `aaa`
- **Multi-Hop:** `~/greyhack-tools/multihop_strike.src` — Dee → LAN-Scan → Royal (ADMIN)

> Diese Datei wird still im Hintergrund aktualisiert, bevor der Kontext komprimiert wird.
> GreyHack-spezifische Sektionen niemals manuell löschen — sie sind die Grundlage für
> Session-Kontinuität über Missionen hinweg.