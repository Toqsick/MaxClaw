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

### v3.0: 5-Phasen-Queen-Workflow (NEU — konkret angewendet)

Beim v3.0-Upgrade wurde genau dieses Pattern mit **5 parallelen Subagenten** gefahren. Die 5 Phasen:

```
Phase 1: Parallel Research    (3-5 Subagenten, ~5-10 min je)
Phase 2: Immediate Fixes      (parallel im Parent)
Phase 3: Synthesis            (merge + cross-check)
Phase 3.5: Cross-Check        (verifiziere Artefakte existieren — NICHT vertrauen!)
Phase 3.6: User-Anker         (2-4 Optionen zur Wahl, keine offenen Fragen)
Phase 4: Execute & Document   (P0 first)
Phase 5: Retrospective        (was worked, was not)
```

Konkret beim v3.0-Upgrade wurden 5 Subagenten dispatcht:

| Lane | Subagent-Rolle | Liefer-Artefakte |
|------|----------------|------------------|
| 🔧 DB-Analyst | Sandbox-Snapshot + Diff-Engine | `greyhack-db-snapshot.sh`, `greyhack-db-analyze.py`, Cron-Workflow |
| 🛠️ Tool-Builder-Refactor | Best-Practices aus 28 yuno-tools + MaxClaw v3.0 Settings | 6 Agent-Files neu, openclaw.json |
| 📋 Workflow-Architekt | 5 neue autonome Crons | 5 Cron-Defs + register-workflows.sh UPDATE |
| 📚 Skill-Set-Author | 9 Allround-Skills | 8 neue Skills + INSTALL.md + SKILL-INDEX.md |
| 🛡️ Security-Auditor | Self-Audit + Patch-Vorlage | 20-Findings-Report + hardening-config |

Nach Phase 3.6 wurden die Subagent-Ergebnisse verifiziert (`ls -la`, `bash -n`, `py_compile`,
`yaml.safe_load`) — nicht blind vertraut. Siehe [`../AGENT-UPGRADE-2026-07-04.md`](../AGENT-UPGRADE-2026-07-04.md)
für die ausführliche Retrospektive inkl. der **Queen-Pitfall-Checkliste**:

- **Pitfall #5: Verify EVERY claim** — Subagent-Selbstauskünfte sind Selbstberichte, keine Fakten.
  Nach jedem delegaten Task: `ls`, `bash -n`, `python3 -c`, `pyyaml.safe_load` zur Verifikation.
- **Pitfall #10: Model-Param wird ignoriert** bei `openclaw cron add` — Modell wird via
  Job-/Session-Provider nachgepinnt (Flag-Namen mit `openclaw cron --help` prüfen).

## Nächste Ausbaustufe
→ [Block 5 — Automatisierung](05-automatisierung.md)
