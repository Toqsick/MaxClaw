# Workflow: Wöchentlicher Security-Audit

**Typ:** Cron-Job · **Zeitpunkt:** Montag 09:00 · **Modell:** `main` · **Deliver:** Telegram

## Ziel
Read-only-Sicherheitscheck von Desktop + GCP VM. **Report zuerst, Fixes nur nach Freigabe.**

## Was geprüft wird
1. **MaxClaw-Setup:** Gateway-Interface offen im Internet? Port 18789 von außen erreichbar?
2. **Dateiberechtigungen:** zu offen (world-writable, 777)?
3. **Offene Ports / Dienste:** unerwartete Listener?
4. **Skills/Plugins:** seit letztem Audit neu installiert? Prompt-Injection-Verdacht?
5. **Secrets:** liegen Keys im Klartext irgendwo herum?

## Prompt (self-contained)
```
Führe einen READ-ONLY Security-Audit durch (Desktop + GCP VM). Prüfe: ist der MaxClaw-Gateway-
Port 18789 von außen erreichbar (sollte nur 127.0.0.1 sein)? world-writable Dateien/777-Rechte?
unerwartete offene Ports/Dienste? neu installierte Skills/Plugins mit Prompt-Injection-Verdacht?
Klartext-Secrets? Schreibe einen PRIORISIERTEN Report (P0/P1/P2) nach ~/docs/system/
security-audit-<datum>.md. WENDE KEINE FIXES AN — liste sie nur mit Aufwand/Nutzen auf. Schicke
Basti per Telegram die Kurzfassung (nur P0/P1) + Pfad zum vollen Report. Deutsch.
```

## Einrichten
```bash
#   Schedule: "0 9 * * 1"   (Montag 09:00)
#   Deliver:  telegram
```

## Pitfalls
- ❌ Fixes eigenmächtig anwenden → Basti will erst Report, dann Freigabe.
- ❌ Ollama-Modelle (76 GB) als „Müll" markieren → nicht blind löschen.
- ✅ Immer priorisieren (P0 = kritisch, sofort).
