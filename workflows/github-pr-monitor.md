# Workflow: GitHub PR/Issue-Monitor

**Typ:** Cron-Job · **Zeitpunkt:** 2×/Tag (09:00, 17:00) · **Modell:** `main` · **Deliver:** Telegram

## Ziel
Überblick über offene PRs und Issues in den Toqsick-Repos — kurz zusammengefasst, damit nichts
liegen bleibt.

## Was geprüft wird
1. Offene PRs in `Toqsick/greyhack-tools`, `Toqsick/hermes-v7`, `Toqsick/MaxClaw`.
2. Neue Issues seit letztem Lauf.
3. PRs, die auf Review warten oder CI-Fehler haben.

## Prompt (self-contained)
```
Liste offene PRs und neue Issues (seit letztem Lauf) in Toqsick/greyhack-tools,
Toqsick/hermes-v7 und Toqsick/MaxClaw. Für jeden PR: Nummer, Titel, Autor, CI-Status,
wartet-auf-Review-ja/nein. Fasse in max. 10 Zeilen zusammen, priorisiere PRs mit rotem CI oder
offenem Review. Wenn nichts Neues/Offenes → gib nur "Keine offenen Punkte" zurück. Deutsch.
Nutze die gh CLI (Account Toqsick ist eingeloggt).
```

## Einrichten
```bash
#   Schedule: "0 9,17 * * *"
#   Deliver:  telegram
```

## Pitfalls
- ❌ Alle geschlossenen PRs mitlisten → nur offene/neue.
- ✅ CI-rote PRs zuerst.
