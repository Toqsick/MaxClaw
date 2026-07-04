# HEARTBEAT.md — periodische Checkliste (v3.0)

> Das Gateway weckt MaxClaw standardmäßig **alle 30 Minuten** und liest diese Datei.
> Trag nur Dinge ein, die wirklich periodisch geprüft werden müssen.
> ⚠️ Jeder Heartbeat ist ein API-Call und lädt alle Core-Dateien → **günstiges Modell** nutzen!

## Aktive Checks

<!-- Format: - [ ] Beschreibung — was tun, wenn Bedingung erfüllt -->

### Allgemein

- [ ] **Wichtige Termine:** Prüfe, ob in den nächsten 2 h ein wichtiger Termin ansteht.
      Falls ja → Basti per Telegram erinnern.

### GreyHack-spezifisch (NEU v3.0)

- [ ] **Active Mission-Status** (billig, alle 30 min OK): Lade `MEMORY.md` → `## Active
      Missions`. Wenn `status: recon` länger als 2 h ohne Update → kurze Telegram-Erinnerung
      an Basti („Recon zu Reraldi-IP seit 2h offen — soll ich Subagenten starten?").
- [ ] **Tool-Build-Rotation** (billig): Falls neue `.src` in `~/greyhack-tools/` seit
      letztem Heartbeat → `greybel build` Versuch im Sandbox-Verzeichnis loggen (NICHT
      automatisch pushen — nur Result in MEMORY.md → `## GreyHack-Build-Errors`).

### GitHub / Build

- [ ] **GreyHack-CI:** Falls seit letztem Check ein neuer Commit auf `develop` von
      `Toqsick/greyhack-tools` liegt → prüfen, ob der greybel-Build grün ist. Falls rot →
      Telegram-Alert mit betroffenem Tool.

## Heartbeat-Limitierung (NEU v3.0)

Damit das Heartbeat-Modell (günstig) nicht überlastet wird:

- **Billig (< 1 s Modellzeit):** Status-Check, MEMORY.md-Diff, Termine.
- **Heavy (NICHT im Heartbeat — als Cron-Job):** greybel build validation, neue
  GreyScript-Generierung, Recon-Subagent-Starts.
  → Diese laufen in `workflows/greyhack-*.md` mit eigenem Cron-Schedule und `models.heavy`.

## Bewusst NICHT im Heartbeat (→ als Cron-Job, feste Zeit)

- Daily-Briefing (07:00) → siehe workflows/daily-briefing.md
- Security-Audit (Mo 09:00) → siehe workflows/security-audit-weekly.md
- GitHub-PR-Monitor (2×/Tag) → siehe workflows/github-pr-monitor.md
- **NEU:** GreyHack-Sandbox-Recon (alle 6 h) → siehe workflows/greyhack-sandbox-recon.md
- **NEU:** GreyHack-Tool-Build-Validator (täglich 22:00) → siehe workflows/greyhack-build-validator.md

> Steht nichts an, antwortet MaxClaw intern nur „Heartbeat OK" — das Gateway unterdrückt das,
> Basti bekommt keine Nachricht.