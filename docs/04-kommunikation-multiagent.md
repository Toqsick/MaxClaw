# Block 4 — Kommunikation & Multi-Agent

## Ziel in einem Satz
Verstehen, wie du mit MaxClaw kommunizierst (Gateway, Channels, Sessions) und wie du mehrere
Agenten und Subagenten einsetzt.

## Das Gateway — die zentrale Schnittstelle
Jede Nachricht (egal ob WhatsApp, Telegram, Slack …) landet **zuerst beim Gateway** —
wie der Empfang in einem Bürogebäude. Es:
1. nimmt die Nachricht entgegen,
2. schaut, in welchem Gespräch du bist,
3. lädt alles, was MaxClaw braucht,
4. gibt es ans KI-Modell,
5. schickt die Antwort denselben Weg zurück.

## Channels — die Telefonleitungen
Jede Plattform-Verbindung ist ein **Channel** (Telegram, WhatsApp, Slack, Signal, iMessage,
Teams, Nextcloud Talk … >20 Plattformen). Du kannst mehrere Channels gleichzeitig betreiben.

## Sessions — getrennte Gesprächsstränge
Eine **Session** ist ein Gesprächsstrang mit eigenem Verlauf. Telegram-Projektchat = eine
Session, WhatsApp = eine andere. Vorteil:
- Themen bleiben sauber getrennt, nichts vermischt sich.
- Mehrere Personen gleichzeitig? Kein Problem — jede Session wird **unabhängig** verarbeitet;
  der Agent sieht immer nur den Verlauf der jeweiligen Session.

### Queue (Warteschlange)
Schickst du 3 Nachrichten schnell hintereinander, verarbeitet das Gateway sie **der Reihe nach**.
Langsamer, aber verhindert Konflikte (z. B. zwei Nachrichten, die dieselbe Datei ändern wollen).

## Multi-Agent — mehrere feste Agenten
Du kannst **mehrere Agenten in einem Gateway** betreiben. Bürogebäude-Analogie: jeder Agent
hat ein eigenes Büro (eigener Workspace, eigene Soul/User/Agents/Identity, eigene Skills, eigene
Queue). Sie teilen nur die Infrastruktur.

Beispiel-Rollen:
- **Personal Assistant** — Kalender & Termine
- **Coding Agent** — Apps/Skripte programmieren
- **Sales Agent** — Leads/Kaltakquise

### Agent Binding
Zuordnung Channel → Agent: „Telegram → Personal Assistant, WhatsApp → Sales Agent, Discord →
Coding Agent". So weiß das Gateway, wohin es routen muss. Du kannst im Chat auch sagen
„sprich mit Agent X" und das Gateway wechselt.

> 💡 Denk in **Rollen**, nicht nur Aufgaben: Welche 2–3 Arbeitsbereiche sind so unterschiedlich,
> dass ein eigener Agent Sinn ergibt? Damit fängst du an.
> Einrichten? Einfach dem Hauptagenten sagen „richte einen Coding-Agent ein" — er macht es.

## Subagenten — temporäre Aushilfen (≠ feste Agenten!)
Wichtige Unterscheidung:
- **Agent** = fester Mitarbeiter mit eigenem Büro, dauerhaft.
- **Subagent** = temporäre Aushilfe (Praktikant): wird spontan gestartet, erledigt eine
  Teilaufgabe, liefert das Ergebnis zurück, **verschwindet dann**. Kein eigener Workspace,
  keine Persistenz.

### Warum Subagenten essenziell sind
Bei jedem Schritt im Agentic Loop **wächst der Kontext**. Problem: **Context Rot** — je voller
das Kontextfenster, desto schlechter die Antwortqualität (Details werden übersehen, Fehler
schleichen sich ein). Das Kontextfenster ist wie Kurzzeitgedächtnis.

**Lösung:** Aufwendige Teilaufgaben (z. B. viel Recherche, viele Zwischenschritte) an einen
Subagenten delegieren. Der hat sein **eigenes** Kontextfenster, füllt es voll und gibt nur das
**Ergebnis** zurück. Das Kontextfenster des Hauptagenten bleibt schlank → Qualität bleibt hoch.

**Bonus — Kostenvorteil:** Hauptagent auf starkem Modell (Opus), Subagenten auf billigem
(Gemini Flash) → billiger, weil Recherche keine Top-Power braucht.

**Beispiel:** Blogartikel-Agent bekommt „schreib Artikel über X" → startet Recherche-Subagenten
→ die liefern Rohtexte → Hauptagent schreibt daraus den Artikel, minimal belastetes
Kontextfenster, hohe Qualität.

## Unser MaxClaw-Setup (Basti)
- **Input-Flow:** Wenn MaxClaw eine Entscheidung/Eingabe braucht → aktiv per **Telegram-DM**
  fragen (mit knappen Auswahloptionen), statt inline zu warten.
- **Orchestrierung** ist das eigentliche Lernziel — Multi-Agent mit Rollen (Architekt,
  Implementierer, Validator) auch als Parent-Direct-Fallback effektiv. Metapher:
  Bienenkönigin befehligt ihren Schwarm. 🐝

## Nächste Ausbaustufe
→ [Block 5 — Automatisierung](05-automatisierung.md)
