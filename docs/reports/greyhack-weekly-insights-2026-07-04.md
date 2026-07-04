# GreyHack Weekly Insights — KW 27 (2026-06-28 → 2026-07-04)

> **Distiller:** MaxClaw (heavy model, Hermes `default`-Profil)
> **Zeitfenster:** 7 Tage, Eingrenzung 2026-06-28 (00:00) → 2026-07-04 (23:59 Lokal)
> **Input-Quellen:** 6 system-doku Files, Skill-Refs, MaxClaw v3-Upgrade-Briefing, GreyHackDB.db-Snapshot
> **Hinweis Archivierung:** Bei >12 Wochen → älteste nach `~/docs/system/archive/` verschieben.

---

## Highlights (5)

1. **YUNO V6 in-game deployed** — `//command: yuno_v6` (78 KB Source, 45 KB Build, 60+ Commands) wurde auf den Spieler-PC `gregor@219.50.230.162` überführt; 12/12 Mock-Tests grün, 0 P0-Bugs. Die 6 V6-Features (Disk-Persistenz, State-Restore, Plugin-Auto-Load, History-Suggest, Sniffer-Integration, Coop-Mode) sind alle im Build.
   *Quelle:* `~/docs/system/greyhack-yuno-v6-2026-07-03.md` + `~/docs/system/greyhack-yuno-v6-deploy-2026-07-04.md:1-15`

2. **GreyHackDB.db vollständig katalogisiert** — 19 Tabellen, 248 Files (refCount 258), 267 Passwörter im Klartext, 56 Hosts in 15 Netz-Typen, InfoGen mit 1.95 MB Exploit-Configs. Wichtigste versteckte Credentials: **gregor@gusesamoz.org : Adelholzener** (Mail+Bank+12-Zeichen-Easter-Egg).
   *Quelle:* `~/docs/system/greyhack-deep-content-2026-07-04.md:13-28`, `~/docs/system/greyhack-deep-research-2026-07-04.md:10-25`

3. **Mission-Belohnung nicht eingelöst** — `16.174.201.225` (Erpillinek_AB5B7) wurde bereits via FTP→SSH-Bounce gehackt, aber `firstMissionRewardClaimed=false`. **68$ liegen brach.** Drei neue APT-Repo/C2-IPs gefunden: `211.49.68.91`, `209.94.10.145`, `32.119.19.133`.
   *Quelle:* `~/docs/system/greyhack-deep-research-2026-07-04.md:27-34`

4. **MaxClaw v3.0 als GreyHack-Arbeiter aufgesetzt** — 5 neue Crons (db-snapshot, db-watcher, mission-tracker, tool-backup-watch, **knowledge-distiller**), 8 neue Allround-Skills (sandbox-snapshot, sqlite-reader, greyscript-linter, …). Fehler bei Registrierung dokumentiert: `hermes cron create` akzeptiert kein `--model`.
   *Quelle:* `~/docs/system/maxclaw-v3-upgrade-2026-07-04.md:34-53`, `/tmp/maxclaw-clone/AGENT-UPGRADE-2026-07-04.md:1-20`

5. **Storage-Cleanup hat 47.75 GB freigeräumt** — Spieler-PC war 102% voll (358 GB belegt / 350 MB HDD-Kapazität). 7 eigene Test-Scripts aus `/bin/` und 3 Test-Files aus `/server/aptfiles/` gelöscht (immer noch −40 GB über Kapazität).
   *Quelle:* `~/docs/system/greyhack-storage-cleanup-2026-07-03.md:1-25`

---

## Neue Patterns / Bugs

### Pattern NP-69: `yuno defend` stürzt ab bei Ports ohne `service`-Map-Field
- **Repro:** Mock-Env mit Port ohne `service`-Property → `defend` wirft TypeError
- **Fix:** Robuster `typeof()` Check + `indexOf` vor jedem Map-Zugriff (Zeile 409-427 in `yuno.src`)
- **Status:** ✅ Gefixt + re-tested
- *Quelle:* `~/docs/system/greyhack-storage-cleanup-2026-07-03.md:108-114`

### Pattern NP-70: Multi-Agent-Truncation bei FileSystem-JSON >15 KB
- **Symptom:** 3-Experten-Deep-Dive (2026-07-04) — Content-Expertin 359s/56 API-Calls, 2 von 3 Reports truncated bei großen JSON-Strukturen (FileSystem mit 418 Ordnern)
- **Mitigation:** Max API-Calls auf 40 begrenzen; bei FileSystem-Analysen erst Baumstruktur zählen, dann Ausschnitte; 4. Expertin als Validatorin
- *Quelle:* `~/docs/system/greyhack-deep-research-2026-07-04.md:101-118`

### Pattern NP-71: `hermes cron create --model` still ignoriert
- **Repro:** Versuch `hermes cron create ... --model heavy` — Flag wird geschluckt
- **Mitigation:** `register-workflows.sh` nutzt `model`-Werte jetzt nur intern (`model_args`); nachträgliches Pin via `cronjob action=update job_id=... model=...`
- *Quelle:* `~/docs/system/maxclaw-v3-upgrade-2026-07-04.md:48-52`

### Pattern NP-72: Dual-ID-Class in `Files`-Tabelle
- **Discovery:** Files-Tabelle hat UUID/MD5-IDs (246 Einträge) UND Pfad-String-IDs (1 Eintrag: `Config/yuno.src`). DB-Injection mit Pfad-ID allein macht Datei nicht im Game sichtbar → zusätzlich `Computer.FileSystem`-JSON-Eintrag nötig
- *Quelle:* GreyHack Skill SKILL.md (Stand 2026-07-04, neuer Eintrag)

### Pattern NP-73: `//command:` Marker + Config/-Pfad zwingend
- **Symptom:** Source-Skripte OHNE `//command:` als erste Zeile oder im Root `/home/<USER>/` statt `/home/<USER>/Config/` → "Can't build. Binary file."
- **Konsequenz:** DB-Injection-Check: erste Content-Zeile muss `//command: <name>` sein
- *Quelle:* GreyHack Skill SKILL.md, alle 46 Source-Scripts in Live-DB haben Pattern

---

## Offene Fragen / Nächste Woche

1. **In-Game-HDD Erweiterung** — Storage-Cleanup hat nur 47.75 GB freigemacht, aber die 350 MB-HDD ist immer noch ~−40 GB über ihrer nominellen Kapazität. Frage: Lohnt sich ein HW-Upgrade im Spiel (größere HDD kaufen), oder besser DB-Whitelist-Pattern erweitern (mehr /server/ Test-Files)?
2. **Mission 16.174.201.225 Belohnung einsacken** — 68$ liegen seit dem Hack brach; nächste Session: einmal `claim` triggern.
3. **`yuno_v6` vs `yuno_v6c` Template-Frage** — V6 = 78 KB Source (uglified, nicht mehr auf Disk, nur Build), V6c = 18 KB Clean-Minimal. Soll der Daily-Driver auf V6 oder V6c migriert werden?
4. **MaxClaw v3 Knowledge-Distiller — Validierung** — dieser Lauf ist der erste echte Distill. Output prüft am Sonntag: ist die Notiz substanziell genug, oder wiederholen sich nur Findings aus dem Highlight-Stream?

---

## Quellen-Index

| Datei | Größe | Cluster-Beitrag |
|-------|------:|------------------|
| `~/docs/system/greyhack-yuno-v6-2026-07-03.md` | 6 KB | Build / In-Game-Ready V6 |
| `~/docs/system/greyhack-yuno-v6-deploy-2026-07-04.md` | 17 KB | Deployment-Workflow (5 Schritte) |
| `~/docs/system/greyhack-deep-content-2026-07-04.md` | 32 KB | File-/Content-Inventar, Credentials |
| `~/docs/system/greyhack-deep-systems-2026-07-04.md` | 34 KB | 18 Computer-Bäume + Hardware |
| `~/docs/system/greyhack-deep-intel-2026-07-04.md` | 30 KB | Connection-Map, Passwort-Statistik |
| `~/docs/system/greyhack-deep-research-2026-07-04.md` | 5 KB | Synthesis + Aktionsplan |
| `~/docs/system/greyhack-storage-cleanup-2026-07-03.md` | 5 KB | Bugfix NP-69 |
| `~/docs/system/maxclaw-v3-upgrade-2026-07-04.md` | 6 KB | Multi-Agent-Truncation (NP-70), Cron-Pitfall (NP-71) |
| `~/docs/system/maxclaw-setup-2026-07-04.md` | (gelesen) | Workflow-Registrierung, model_args-Workaround |
| `~/.hermes/skills/gaming/greyhack/SKILL.md` | 34 KB | NP-72 + NP-73 (Dual-ID, //command:) |
| `/tmp/maxclaw-clone/AGENT-UPGRADE-2026-07-04.md` | 16 KB | 28 yuno-tools GreyScripts als Style-Quelle |

**Audit-Hinweis:** Inputs `~/.local/share/hermes/logs/*.log` und `~/.local/share/maxclaw/cron-output/` aus dem Original-Workflow-Prompt existieren auf dieser Maschine NICHT — substituieriert durch `~/docs/system/greyhack-*-2026-07-*.md`. MISSION-LOG.md ebenfalls nicht vorhanden; Spiel-Aktivität aus den 3 Deep-Reports + Storage-Cleanup abgeleitet.

---

## Telegram-Kurzfassung (für Sonntag-Abend)

> 🐝 **GreyHack KW27 — Highlights:**
> 1. **YUNO V6 in-game:** 60+ Commands, 12/12 Tests grün, 0 P0-Bugs ✅
> 2. **GreyHackDB katalogisiert:** 248 Files, 267 Pwd im Klartext, 1 Easter-Egg 🍶
> 3. **Mission-Belohnung verfallen:** 68$ auf `16.174.201.225` nicht eingelöst
> 4. **MaxClaw v3 online:** 5 Crons + 8 Skills, Knowledge-Distiller = dieser Lauf
> 5. **Storage-Cleanup:** 47.75 GB raus, brauchen trotzdem größere HDD
>
> ❓ **Offene Frage:** In-Game-HDD upgraden oder DB-Whitelist erweitern? (350 MB voll, −40 GB nach Cleanup)
