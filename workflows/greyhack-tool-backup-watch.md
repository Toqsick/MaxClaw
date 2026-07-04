# Workflow: GreyHack Tool-Backup-Wächter

**Typ:** Cron-Job (Watchdog) · **Zeitpunkt:** alle 6 Stunden · **Modell:** `heartbeat` (kein LLM — git + Bash) · **Deliver:** Telegram (nur bei „dirty" oder „überfällig")

## Ziel
Sicherstellen, dass Bastis GreyHack-Tool-Repo (`~/greyhack-tools/`) **nie länger als 3 Tage ohne
Commit/Push** bleibt — das ist die Backup-Garantie für seine Basteleien. Wenn `git status` schmutzig
ist ODER der letzte Push > 72 h zurückliegt → Telegram-Alarm. Sonst: still.

## Warum?
Basti arbeitet oft stundenlang an Tool-Refactorings in der Sandbox, vergisst aber zwischendurch
zu committen und zu pushen. Wenn dann die Platte stirbt oder der Container crasht, sind die
Änderungen weg. Der Wächter erinnert sanft, bevor das Zeitfenster kritisch wird.

## Was passiert pro Lauf
1. **Dirty-Check:** `cd ~/greyhack-tools && git status --porcelain`. Wenn nicht leer → Telegram:
   „📂 Dirty Working Tree: <Anzahl Dateien> + <kurze Liste>".
2. **Last-Push-Check:** `git log -1 --format=%ct origin/develop` (Unix-Timestamp). Wenn älter als
   259200 Sekunden (3 Tage) → Telegram: „⏰ Letzter Push vor X Tagen — bitte committen & pushen".
3. **Sonst:** silent exit.
4. **Zusätzlich (alle 24 h, intern):** Repo-Statistik ans `~/greyhack-tools/.backup-state` anhängen
   (für Trend-Auswertung im Knowledge-Distiller).

## Prompt (self-contained — sehr kurz, fast Shell)
```bash
#!/usr/bin/env bash
# GreyHack Tool-Backup-Wächter — silent on success
set -euo pipefail
cd ~/greyhack-tools || exit 0

DIRTY=$(git status --porcelain | wc -l)
LAST_PUSH=$(git log -1 --format=%ct origin/develop 2>/dev/null || echo 0)
NOW=$(date +%s)
AGE=$(( NOW - LAST_PUSH ))

if [[ "$DIRTY" -gt 0 ]]; then
  echo "📂 Dirty Working Tree: $DIRTY Dateien:"
  git status --porcelain | head -10
fi

if [[ "$AGE" -gt 259200 ]]; then
  DAYS=$(( AGE / 86400 ))
  echo "⏰ Letzter Push vor $DAYS Tagen — bitte committen & pushen."
fi

exit 0
```

> Das ist ein **Shell-Wrapper**, kein LLM-Job. Im `hermes cron create`-Aufruf wird der obige
> Code als `--command` übergeben statt als Prompt; Skills entfallen.

## Einrichten
```bash
#   Schedule: "0 */6 * * *"   (alle 6 h: 00, 06, 12, 18)
#   Deliver:  telegram:7222661188 (nur bei Alarm — Watchdog)
#   Skills:   —  (deterministisches Bash-Script)
#   (registriert via ./workflows/register-workflows.sh)
```

## Pitfalls
- ❌ **Bei jedem Lauf pushen** → das ist Aufgabe von Basti/MaxClaw-Tool-Builder, nicht dieses
  Wächters. Hier nur **alarmieren**.
- ❌ **Bei dirty-Working-Tree pushen** → verboten: Working Tree könnte Mid-Refactor sein, das
  würde halbe Arbeit ins Remote schieben.
- ❌ **3-Tage-Frist zu kurz wählen** → Basti arbeitet manchmal eine Woche an einem Feature
  bewusst am Stück und pusht am Ende. 3 Tage ist die **Erinnerungsschwelle**, nicht ein Hard-Limit.
- ✅ **Heartbeat-Modell** — git-Output ist deterministisch; LLM wäre Verschwendung.
- ✅ **Zustand in `.backup-state` loggen** — der Knowledge-Distiller (Sonntag 22 h) kann daraus
  Trends lesen (Bastis Push-Frequenz, Dirty-Häufigkeit).