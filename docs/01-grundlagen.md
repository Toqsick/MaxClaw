# Block 1 — Grundlagen & Installation

## Ziel in einem Satz
Verstehen, was MaxClaw ist, wodurch es sich von Chatbots unterscheidet und wo man es installiert.

## Was MaxClaw ist (und was nicht)

**Kein Chatbot.** ChatGPT, Claude, Gemini sind beeindruckend, aber alles passiert *in ihrem
Chatfenster*. Du machst den ersten Schritt, du kopierst das Ergebnis raus, du machst die
Zwischenschritte.

**MaxClaw läuft auf einem echten Rechner/Server** und hat vollen Zugriff:
- Dateien erstellen, bearbeiten, verschieben, löschen
- Programme installieren & ausführen
- im Internet surfen, sich in Apps einloggen, APIs ansprechen
- **eigene Fähigkeiten erweitern** — er schreibt sich selbst Skripte, konfiguriert sich selbst

Anders als n8n (wo du den Workflow Schritt für Schritt baust) kann MaxClaw sich eine Funktion
**selbst neu erstellen**.

**Proaktiv.** MaxClaw wartet nicht auf dich. Er kann morgens Termine prüfen, ein Briefing
schicken, im Hintergrund Aufgaben abarbeiten — und dir das Ergebnis per Telegram schicken,
während du schläfst.

> 🧠 Merksatz: ChatGPT = kluger *Berater* im Gespräch. MaxClaw = *Mitarbeiter* mit eigenem Schreibtisch.

## Open Source
OpenClaw ist Open Source — der Code ist öffentlich. Kein Unternehmen kontrolliert es, niemand
kann es hinter eine Paywall packen, jeder kann unter die Haube schauen. **MaxClaw** ist die
konkrete OpenClaw-Instanz von minimax.

## Wo installieren? (die wichtigste Entscheidung)

**Nicht auf deinem Hauptrechner.** Analogie: Du würdest einem neuen Mitarbeiter am ersten Tag
nicht deinen privaten Laptop mit allen Fotos, Passwörtern und Bankdaten geben. Der Agent
bekommt seinen **eigenen Arbeitsplatz**.

Drei Wege:

| Weg | Vorteil | Nachteil |
|-----|---------|----------|
| Alter Laptop zu Hause | kostenlos | nur online wenn Laptop läuft |
| Mac Mini | performant, beliebt in Community | teuer |
| **VPS (empfohlen)** | 24/7 online, saubere Trennung | ein paar € / Monat |

Ein **VPS** (virtueller privater Server, z. B. Hetzner/Hostinger) ist ein Computer in der Cloud.
Worst Case: MaxClaw zerschießt nur den Server — deine wichtigen Sachen liegen lokal oder woanders.

→ Sicheres Server-Setup: **[08-server-deployment.md](08-server-deployment.md)**

## Unser Setup (Basti)
- **Lokaler Linux-Desktop** (Ubuntu 24.04, NVIDIA, Docker) — Haupt-Dev-Maschine.
- **GCP VM** (Ubuntu + Xubuntu) — für 24/7-Workflows & isolierte Tasks.
- Prinzip: kritische Dinge lokal, MaxClaw-Experimente in isolierter Umgebung.

## Häufige Fehler
- ❌ MaxClaw direkt auf dem Hauptrechner mit vollem Zugriff → Datenrisiko.
- ❌ „Installier einfach, wird schon" ohne Security-Block zu lesen.
- ✅ Erst Block 7 (Security) lesen, dann Zugriff geben.

## Nächste Ausbaustufe
→ [Block 2 — Kosten & Modelle](02-kosten-und-modelle.md): Was kostet der Betrieb wirklich?
