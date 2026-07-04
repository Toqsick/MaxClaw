# Block 3 — Das Gehirn des Agenten

## Ziel in einem Satz
Verstehen, welche Dateien MaxClaws Persönlichkeit, Regeln und Gedächtnis ausmachen.

## Zuerst: der Agentic Loop (agentische Schleife)
Grundbaustein für **alles**. Chatbot = einmal hin und her (ein Zug). Ein Agent arbeitet in
einer **Schleife**:

```
Aufgabe → Denken → Handeln (Schritt ausführen) → Beobachten (Ergebnis prüfen) → Denken → …
        ↑___________________________________________________________________|
                          bis die Aufgabe erledigt ist
```

Beispiel „Fix diesen Bug": Datei lesen → Fehler suchen → Code ändern → Programm testen →
schlägt fehl → andere Lösung → testen → grün → „Bug gefixt!". Aus **einer** Frage werden
**6–7 Aktionen**, automatisch.

## Der Workspace
Wenn MaxClaw startet, braucht er ein Zuhause: einen Ordner mit Konfiguration, Gedächtnis und
Anweisungen. Standard: `~/.openclaw/agent/` (bei Hermes: `~/.hermes/`).
Alle Dateien darin sind **ganz normale Markdown-Textdateien** — kein Code, lesbar & editierbar.

## Die Core-Dateien (Vorlagen in [`../agent/`](../agent/))

| Datei | Rolle | Frage, die sie beantwortet |
|-------|-------|----------------------------|
| **SOUL.md** | Persönlichkeit | *Wer bin ich?* Ton, Werte, Verhalten |
| **IDENTITY.md** | Identität (kurz) | Name, Vibe, Emoji, Avatar — **v3.0: GreyHack-Track-Kompetenzen** |
| **AGENTS.md** | Betriebshandbuch | *Wie arbeite ich?* — **v3.0: GreyHack-Operationen + Mission-Lifecycle** |
| **USER.md** | über dich | Wer ist der Mensch? Name, Zeitzone, Projekte, Vorlieben |
| **TOOLS.md** | Notizbuch | **v3.0: Syntax-Regel-Tabelle + 5 Code-Idiome + Build-Aufruf-Box** |
| **MEMORY.md** | Langzeitgedächtnis | **v3.0: 6 Sub-Sektionen** (Missions, Tool-Registry, Build-Errors, NPC-Intel, DB-Snapshots, Lessons-Learned) |
| **HEARTBEAT.md** | Checkliste | **v3.0: heavy/billig-Trennung** + Mission-Status |
| **daily/** | Arbeitstagebuch | Was ist an Tag X passiert? |

### SOUL.md — die Persönlichkeit
Definiert Ton (formell vs. locker), Kommunikationsstil, Werte, Verhaltensregeln.
Startet mit einer Initial-Version, die du über die Zeit verfeinerst. *„You are not a chatbot
becoming someone. Be genuinely helpful, not performatively helpful."*

### AGENTS.md — das Betriebshandbuch (wichtigste Datei)
Die obersten Anweisungen: *nie etwas ohne Freigabe veröffentlichen*, *immer Kalender prüfen
vor Terminvorschlag*, *sensible Aktionen erst nachfragen*. Lebendiges Dokument.
> 💡 Tipp: Baue einen **täglichen Selbstverbesserungs-Loop** ein — am Ende jeder Session
> reflektiert MaxClaw, was gut/schlecht lief, und schlägt Updates für seine Core-Dateien vor.

### v3.0: GreyHack-Track in den Agent-Files

MaxClaw v3.0 ist explizit auf **GreyHack** als eine Hauptkompetenz ausgerichtet. Das findet sich in mehreren Files:

**IDENTITY.md v3.0:**
- Liste der GreyHack-Operationen, die MaxClaw beherrscht (portscan, bruteforce, metaxploit-Chains, deep_recon, hardening_audit, mission_chains)
- **Negativliste**: was MaxClaw auf KEINEN Fall tut (live pentesting, externe Systeme, Datenklau)
- Mission-Lifecycle-States: `todo → briefing → active → blocked → done → archived`

**AGENTS.md v3.0:**
- Welche GreyHack-Tools sind erlaubt (`metaxploit`, `shell.build`, `pc.wget`, `cryptools`, `include_lib`)
- Build-Pipeline-Checkliste (pc.wget → shell.build → delete) für jeden neuen Tool-Lauf
- Default-Deny bleibt unangetastet: `git push main`, world-write, System-Files

**TOOLS.md v3.0:**
- **Syntax-Regel-Tabelle** als Schnellreferenz: `greybel build OHNE -u`, `//command:` erste Zeile Pflicht
- **5 Code-Idiome** (Lib-Loader, Null-Check, Port-Scan-Loop, Home-Looter, Param-Parser)
- **Build-Aufruf-Box** mit Copy-Paste-Befehl

**MEMORY.md v3.0:**
- 6 strukturierte Sub-Sektionen — nicht mehr ein Freitext-Eimer:
  1. **Active Missions** (Spielwelt-Status, IPs, Ziele)
  2. **Tool Registry** (welche .src-Datei baut was, Commit-Hashes)
  3. **Build Errors** (bekannte greybel-Fehlermeldungen + Fix)
  4. **NPC Intel** (welche NPCs wo, welche Texte schon gesehen)
  5. **DB Snapshots** (Spielwelt-Inventar-Historie)
  6. **Lessons Learned** (Bastis Vorlieben aus früheren Sessions)

> 🐝 **Warum so strukturiert?** Die 5-Subagenten-Queen-Orchestration liefert pro Subagent
> ein anderes Memory-Subset. Strukturierte Felder = LLM kann sie ohne Parsing-Hell direkt nutzen.

### MEMORY.md + Daily Notes — dauerhaftes Gedächtnis
Die meisten KI-Tools vergessen alles beim Chat-Ende. MaxClaw nicht:
- **Daily Notes** (`daily/2026-07-03.md`): Arbeitstagebuch pro Tag.
- **MEMORY.md**: Langzeitgedächtnis für dauerhaft Wichtiges.

## Context Engine & Kompression
Jedes Modell hat ein begrenztes **Kontextfenster** (z. B. Opus 4.6 ≈ 1 Mio. Tokens ≈ so viel
Text wie die ganze Bibel). Wird ein Gespräch zu lang, **komprimiert** die Context Engine ältere
Teile zu einer Zusammenfassung. Details können dabei verloren gehen → deshalb sichert MaxClaw
Wichtiges **vorher** still in MEMORY.md.

**Modular:** Die Context Engine ist selbst ein Plugin und austauschbar. Community-Plugin
*Lossless Claw* baut statt Sliding-Window einen **Wissensgraphen** — nichts wird gelöscht,
nur intelligent priorisiert. (Fortgeschritten; Standard reicht für den Anfang.)

## Häufige Fehler
- ❌ Alles in eine riesige SOUL.md packen → jeder Token wird bei *jeder* Nachricht bezahlt.
- ❌ AGENTS.md ohne „frag-vorher"-Regeln bei destruktiven Aktionen.
- ✅ Core-Dateien kompakt & hochsignalhaltig halten.

## Nächste Ausbaustufe
→ [Block 4 — Kommunikation & Multi-Agent](04-kommunikation-multiagent.md)
