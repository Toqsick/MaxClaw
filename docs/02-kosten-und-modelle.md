# Block 2 — Kosten & Modelle

## Ziel in einem Satz
Verstehen, warum MaxClaw Geld kostet, wie man Modelle wählt und wie man Kosten begrenzt.

## Grundprinzip
MaxClaw/OpenClaw selbst ist **kostenlos** (Open Source). Aber es braucht ein **KI-Modell**
im Hintergrund, das die Denkarbeit übernimmt — und das kostet Geld (außer du hostest ein
Modell lokal, wofür du starke Hardware brauchst).

## Zwei Wege der Anbindung

### 1. API-Key (pro Nutzung)
- Ein Schlüssel gibt Zugang zum Modell, du zahlst **pro Token**.
- Jede Nachricht, jede Aktion, jeder Denkschritt kostet.
- **Keine Obergrenze** — ein fleißiger Agent kann teuer werden.
- Für Leute, die ihre Kosten aktiv im Blick behalten.
- **Tipp:** Bei [OpenRouter](https://openrouter.ai) bekommst du *alle* Modelle mit einem Key
  (Gemini, Claude, GPT + chinesische Modelle) und kannst **pro Key ein Limit** setzen
  (z. B. 20 €/Monat → danach stoppt MaxClaw).

### 2. OAuth (festes Abo)
- Nutzt ein bestehendes Abo (z. B. ChatGPT Plus) → **fester Betrag/Monat**, egal wie viel
  der Agent arbeitet. Sehr vorhersehbar, aber mit Rate-Limits.
- **OpenAI:** offiziell erlaubt (seit Peter Steinberger dort ist). ✅
- **Ollama Cloud:** OAuth möglich, viele Open-Source-Modelle (z. B. Kimi K2.5). ✅
- **Anthropic:** OAuth für OpenClaw **blockiert** (Anfang 2026) → Claude nur per API-Key. ❌
- **Google:** riskante Grauzone, dokumentierte Account-Sperren → Finger weg. ⚠️

> 💡 Für regelmäßige, langfristige Nutzung ist **OAuth** (OpenAI oder Ollama Cloud) meist die
> günstigere, planbarere Wahl.

## ⚠️ Datenschutz-Hinweis
Egal ob API-Key oder OAuth — die meisten Dienste routen deine Daten über **Server in den USA**.
Jede Nachricht, jede Datei läuft dort durch. Bei sensiblen/personenbezogenen Daten bewusst
entscheiden. (Ollama Cloud routet *manchmal* über Europa — keine Garantie.)

## Warum MaxClaw viel mehr Tokens verbraucht
Bei ChatGPT = **1 API-Call** pro Nachricht. Bei MaxClaw sind es bei **einer** Aufgabe oft
**5–10+ Aktionen**: Dateien lesen, Tools ausführen, nachdenken, Ergebnis prüfen, korrigieren,
erneut versuchen. Jede Aktion = eigener API-Call = Tokens.

**Dazu kommt:** Bei *jeder* Nachricht werden **alle Core-Dateien** (Soul, Agents, User, …)
mitgeschickt. Sind die zusammen z. B. 10.000 Tokens lang, zahlst du die bei *jeder* Nachricht.
> 1000 Tokens ≈ 750 Wörter. Preise rechnen in Input + Output pro 1 Mio. Tokens.

## Modell-Routing: verschiedene Modelle für verschiedene Aufgaben
Das ist der Schlüssel zu bezahlbarem Betrieb:

| Aufgabe | Empfohlenes Modell | Grund |
|---------|--------------------|-------|
| Alltag / Hauptagent | günstig-aber-gut (Kimi K2.5, GLM) | tägliche Arbeit |
| Coding / komplexe Analyse | stark (Claude Opus, GPT Codex) | Qualität zählt |
| Heartbeat / Routine-Checks | billig | läuft ständig |
| Subagenten (Recherche) | billig (Gemini Flash) | brauchen keine Power |

**Fallback-Funktion:** Ist z. B. das API-Key-Limit von 20 € erreicht, wechselt MaxClaw
automatisch auf ein **kostenloses** Fallback-Modell (OpenRouter hat viele Free-Modelle).

## Unsere Kostenhaltung (Basti)
> Erst kostenlose/lokale Optionen bevorzugen. Kostenpflichtige Modelle nur, wenn der Mehrwert
> konkret begründet ist. Bei Modellvergleichen immer Nutzen + Kosten + Komplexität zusammen sehen.

Siehe [`config/openclaw.json`](../config/openclaw.json) für das konkrete Routing bei MaxClaw.

## Nächste Ausbaustufe
→ [Block 3 — Das Gehirn des Agenten](03-das-gehirn.md)
