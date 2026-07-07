# Workflow: GreyHack Tool-Builder (Sandbox)

**Typ:** Cron-Job · **Zeitpunkt:** alle 2 Stunden · **Modell:** `heavy` (Codix/Opus) · **Deliver:** Telegram · **Skills:** `greyhack`, `greyhack-sandbox`, `greyscript-compiler-debugging`

## Ziel
MaxClaw arbeitet in seiner eigenen **Sandbox** an den GreyHack-Tools: er nimmt sich eine offene
Baustelle aus `bug-patterns` / `known-bugs` / `todo`-Listen und feilt selbständig daran — ohne
dass du etwas tun musst. Nur **bei Fertigstellung oder echtem Fortschritt** meldet er per Telegram.

## Warum eine "Sandbox"?
Basti nennt es „MaxClaw in seiner eigenen Sandbox daran feilen lassen" — Claw soll sich aktiv
am Code ausprobieren dürfen, mit dem `greyhack-sandbox`-Skill sogar **außerhalb des Spiels**
(testbar via `greybel-js`). So lernt das System die Tool-Welt kennen und macht P0-Fixes
selbst.

## Was passiert pro Lauf
1. **Ist-Zustand:** Was ist seit letztem Lauf passiert? Offene P0-Bugs?
2. **Nimm dir EINEN offenen Punkt** (nicht alles auf einmal — Context-Rot vermeiden).
3. **Arbeite** ihn ab in der Sandbox — Build lokal, teste, iteriere.
4. **Verifiziere:** `greybel build` ohne `-u` muss grün sein (siehe [greyhack-ci-watch](greyhack-ci-watch.md)).
5. **Wenn fertig:** committe auf `develop` (nicht main), fasse 3 Bullet-Points zusammen, schicke
   per Telegram. **Wenn nichts offen:** still bleiben.

## Prompt (self-contained)
```
Du bist der GreyHack-Tool-Builder. Prüfe ~/greyhack-tools/ (Branch develop) und die Listen:
- ~/.openclaw/skills/gaming/greyhack/references/known-bugs.md
- ~/.openclaw/skills/gaming/greyhack/references/bug-patterns-*.md

Suche EINE offene Baustelle (P0 > P1 > P2). Arbeite sie in deiner SANDBOX ab: nutze den
greyhack-sandbox-Skill, baue mit greybel build (OHNE -u). Wichtig: kein Einzeiler-if, kein
Inline-if-Ausdruck. Wenn du fertig bist, committe auf develop mit aussagekräftiger Message und
schicke Basti per Telegram: was gemacht, Build-Status, Commit-Hash.

Falls NICHTS offen oder letzter Lauf < 30 min her: antworte nur "no work" und schicke NICHTS.
Deutsch.
```

## Einrichten
```bash
# Schedule: "0 */2 * * *"  (alle 2 Stunden)
# Deliver:  telegram:7222661188
# Skills:   greyhack, greyhack-sandbox, greyscript-compiler-debugging
# (registriert via ./workflows/register-workflows.sh)
```

## Pitfalls
- ❌ Alles auf einmal reparieren wollen → Context-Rot, schlechte Qualität.
- ❌ Direkt auf main committen → tabu (Bastis Regel).
- ✅ **Nur bei Fortschritt** melden — Watchdog-Pattern: still, wenn nichts los.
- ✅ GreHack-Eigenheiten beachten (kein `str_repeat`, `char(10)` für Newline, etc.).