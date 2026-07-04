# Workflow: GreyHack Mission-Tracker

**Typ:** Cron-Job (LLM) · **Zeitpunkt:** alle 4 Stunden · **Modell:** `main` (Reasoning + Greyhack-Kontext) · **Deliver:** Telegram (nur wenn Sub-Steps offen) · **Skills:** `greyhack`, `greyhack-greyscript`

## Ziel
MaxClaw vergleicht Bastis **Missions-Brief** (was er vorhat) mit dem **Mission-Log** (was er gemacht hat)
und erinnert ihn freundlich an offene Ziele/Sub-Steps — **bevor** er beim nächsten Spiel-Start die
Übersicht verliert. Still, wenn alles synchron ist.

## Warum?
Basti plant GreyHack-Missionen in `~/docs/system/greyhack-missions.md` (Freitext-Markdown mit Status-
Checkboxen). Was er tatsächlich gemacht hat, dokumentiert er in `~/greyhack-tools/MISSION-LOG.md`
(z. B. „20:14 — Router 10.0.4.21 kompromittiert via metasploit"). Diese beiden Dateien laufen oft
auseinander: eine geplante Mission steht noch auf „todo", obwohl sie im Spiel schon erledigt ist —
oder umgekehrt. MaxClaw hält sie synchron und pusht Basti sanft an.

## Was passiert pro Lauf
1. **Brief lesen:** `~/docs/system/greyhack-missions.md` → parse alle Mission-Headers (`## Mission …`)
   mit Status-Checkbox (`- [ ]` vs. `- [x]`).
2. **Log lesen:** `~/greyhack-tools/MISSION-LOG.md` → parse chronologische Einträge mit Zeitstempel.
3. **Diff bilden:** Missionen, die im Brief als offen stehen, aber im Log in den letzten 24 h
   eindeutig abgeschlossen wurden → als „done, nicht abgehakt" melden. Missionen, die im Log
   referenziert sind, aber im Brief nicht existieren → als „neue Side-Quest" anbieten.
4. **Wenn nichts offen → nichts senden.** (Watchdog.)
5. **Sonst:** Telegram mit max. 5 Bullet-Points: pro Mission 1 Zeile mit Status + Handlungs-Vorschlag.

## Prompt (self-contained)
```
Du bist der GreyHack-Mission-Tracker. Lese zwei Dateien:
- ~/docs/system/greyhack-missions.md  (Bastis Missions-Brief, Checkbox-Format)
- ~/greyhack-tools/MISSION-LOG.md     (Chronologischer Log, was er im Spiel gemacht hat)

Aufgaben:
1. Parse alle Mission-Header im Brief, prüfe Status (- [ ] = offen, - [x] = erledigt).
2. Parse den Log der letzten 24 h (Datum-Filter) und suche zu jeder offenen Mission passende
   Einträge.
3. Baue 3 Listen:
   a) "fälschlich offen": Mission steht noch auf [ ], aber im Log klar erledigt → vorschlagen,
      abzuhaken (mit kurzem Verweis auf Log-Eintrag).
   b) "im Plan, nichts im Log": offene Mission, zu der es im Log keine Aktivität gibt → freundlich
      erinnern („seit X Tagen unangetastet").
   c) "neu im Log, fehlt im Brief": Missionen/Sub-Steps, die im Log auftauchen, aber keinen Brief-
      Eintrag haben → als Side-Quest zur Aufnahme vorschlagen.
4. Wenn ALLE drei Listen leer sind: antworte nur "missions in sync" und schicke NICHTS an Telegram.
5. Sonst: schicke Basti pro Liste max. 3 Bullet-Points (also max. 9 Telegram-Zeilen). Ton: locker,
   "Kumpel", kein Chef-im-Ring. Deutsch.
Nutze die Skills `greyhack` und `greyhack-greyscript` für Kontext zu typischen Mission-Patterns
(FW-Hack, Bank-Heist, NPC-Quest-Reihen).
```

## Einrichten
```bash
#   Schedule: "0 */4 * * *"   (alle 4 h: 00, 04, 08, 12, 16, 20)
#   Deliver:  telegram:7222661188
#   Skills:   greyhack, greyhack-greyscript
#   (registriert via ./workflows/register-workflows.sh)
```

## Pitfalls
- ❌ **Bei jedem Lauf spammen** → Watchdog-Pattern: nur senden, wenn Diff nicht leer.
- ❌ **Zu viele Missionen** → Telegram-Limit beachten, max. 9 Zeilen; ältere Missionen (>14 d
  ohne Log-Aktivität) zusammenfassen.
- ❌ **Mission-Log parsing zu streng** → Format ist Freitext, kein festes Schema. Im Prompt ist
  „sucht zu jeder offenen Mission passende Einträge" bewusst fuzzy gehalten.
- ✅ **Modell `main`** — Reasoning für die Diff-Bildung nötig, aber kein Opus nötig (4-h-Takt ist
  nicht zeitkritisch und Volumen ist klein).
- ✅ **Skills als parameter** — `greyhack` für Konventionen, `greyhack-greyscript` für Tool-/
  Exploit-Bezug.