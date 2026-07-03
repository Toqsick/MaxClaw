# HEARTBEAT.md — periodische Checkliste

> Das Gateway weckt MaxClaw standardmäßig **alle 30 Minuten** und liest diese Datei.
> Trag nur Dinge ein, die wirklich periodisch geprüft werden müssen.
> ⚠️ Jeder Heartbeat ist ein API-Call und lädt alle Core-Dateien → **günstiges Modell** nutzen!

## Aktive Checks
<!-- Format: - [ ] Beschreibung — was tun, wenn Bedingung erfüllt -->

- [ ] **Wichtige Termine:** Prüfe, ob in den nächsten 2 h ein wichtiger Termin ansteht.
      Falls ja → Basti per Telegram erinnern.
- [ ] **GreyHack-CI:** Falls seit letztem Check ein neuer Commit auf `develop` von
      `Toqsick/greyhack-tools` liegt → prüfen, ob der greybel-Build grün ist. Falls rot →
      Telegram-Alert mit betroffenem Tool.

## Bewusst NICHT im Heartbeat (→ als Cron-Job, feste Zeit)
- Daily-Briefing (07:00) → siehe workflows/daily-briefing.md
- Security-Audit (Mo 09:00) → siehe workflows/security-audit-weekly.md
- GitHub-PR-Monitor (2×/Tag) → siehe workflows/github-pr-monitor.md

> Steht nichts an, antwortet MaxClaw intern nur „Heartbeat OK" — das Gateway unterdrückt das,
> Basti bekommt keine Nachricht.
