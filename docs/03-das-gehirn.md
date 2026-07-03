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
| **IDENTITY.md** | Identität (kurz) | Name, Vibe, Emoji, Avatar |
| **AGENTS.md** | Betriebshandbuch | *Wie arbeite ich?* Regeln, Prioritäten, Grenzen |
| **USER.md** | über dich | Wer ist der Mensch? Name, Zeitzone, Projekte, Vorlieben |
| **TOOLS.md** | Notizbuch | Praktische Notizen zu Tools & Workarounds |
| **MEMORY.md** | Langzeitgedächtnis | Präferenzen, Fakten, zentrale Entscheidungen |
| **HEARTBEAT.md** | Checkliste | Was soll periodisch geprüft werden? (siehe Block 5) |
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
