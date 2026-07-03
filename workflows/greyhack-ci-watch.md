# Workflow: GreyHack CI-Build-Wächter

**Typ:** Cron-Job · **Zeitpunkt:** stündlich (oder nach Push) · **Modell:** `heartbeat` (billig) · **Deliver:** Telegram (nur bei Rot)

## Ziel
Sicherstellen, dass die `greybel`-Builds der GreyHack-Tools nach Commits **grün** bleiben.
Nur bei Fehler alarmieren (Watchdog-Pattern — still, wenn alles ok).

## Was geprüft wird
1. Neuer Commit auf `develop` von `Toqsick/greyhack-tools` seit letztem Check?
2. Falls ja: alle Tools mit `greybel build` bauen (ohne `-u`).
3. Build rot? → Telegram-Alert mit betroffenem Tool + Fehlermeldung.

## Prompt (self-contained)
```
Prüfe das Repo ~/greyhack-tools/ (Branch develop). Falls seit dem letzten Lauf neue Commits
da sind, baue alle .src-Tools mit `greybel build` (OHNE -u). Wichtig: greybel ohne -u kann
keine Einzeiler-if und keine Inline-if-Ausdrücke parsen — das ist ein bekanntes Muster, kein
neuer Bug. Wenn ein Build fehlschlägt, schicke Basti per Telegram: welches Tool, welche
Zeile, welche Fehlermeldung. Wenn alles grün ist, gib NUR "CI OK" zurück (keine Nachricht).
Deutsch.
```

## Einrichten
```bash
#   Schedule: "0 * * * *"   (stündlich)
#   Deliver:  telegram      (aber Prompt sendet nur bei Rot)
```

## Pitfalls
- ❌ Bei jedem grünen Build spammen → nur bei Rot alarmieren.
- ❌ `greybel build -u` erwarten → wir bauen bewusst ohne `-u`.
- ✅ Billiges Modell, da häufiger Lauf.
