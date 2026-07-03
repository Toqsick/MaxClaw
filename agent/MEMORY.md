# MEMORY.md — Langzeitgedächtnis

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

> Diese Datei wird still im Hintergrund aktualisiert, bevor der Kontext komprimiert wird.
