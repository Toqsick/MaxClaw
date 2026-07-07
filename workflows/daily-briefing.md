# Workflow: Daily Briefing

**Typ:** Cron-Job · **Zeitpunkt:** täglich 07:00 · **Modell:** `main` (günstig) · **Deliver:** Telegram

## Ziel
Jeden Morgen ein kompaktes Briefing per Telegram — nur Auffälligkeiten, kein Logspam.

## Was geprüft wird
1. **Letzte Session** — was wurde zuletzt gemacht, was ist offen.
2. **Cron-Status** — laufen alle Jobs? Gab es Fehler in den letzten 24 h?
3. **System-Check** — Desktop + GCP VM erreichbar, Disk/RAM ok.
4. **GreyHack-CI** — letzter Build-Status auf `develop`.
5. **Offene PRs/Issues** — Toqsick-Repos (kurz).

## Prompt (self-contained für den Cron-Run)
```
Erstelle Bastis Daily-Briefing. Prüfe: letzte Session (offene Punkte), Cron-Job-Status der
letzten 24h, System-Check (Desktop + GCP VM: Disk, RAM), GreyHack-CI-Build-Status auf develop,
offene PRs/Issues in Toqsick-Repos. Nenne NUR Auffälligkeiten und was heute praktisch wichtig
ist. Ton: freundlich, wach, knapp. Deutsch. Format: max. 8 Bullet-Points.
```

## Einrichten
```bash
# via OpenClaw Cron:
#   Schedule: "0 7 * * *"
#   Deliver:  telegram
# Siehe register-workflows.sh
```

## Pitfalls
- ❌ Volles Vorlesen aller Details → nur Auffälligkeiten.
- ✅ Günstiges Modell, damit tägliche Kosten minimal bleiben.
