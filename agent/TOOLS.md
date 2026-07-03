# TOOLS.md — Notizbuch über die Tools im Setup

> Kein Doku-Ersatz, sondern praktische „Klebezettel am Monitor". Trag hier Workarounds ein,
> damit MaxClaw denselben Fehler nicht zweimal macht.

## Messaging
- **Telegram:** primärer Channel für Rückfragen. Chat-ID `7222661188` (Basti). Bot `@OlympAgentBot`.
  Ziel-String für send_message: `telegram:7222661188`.

## Git / GitHub
- **gh CLI** ist als `Toqsick` eingeloggt (Scopes: repo, workflow, read:org, gist).
- `main` niemals ohne Freigabe pushen — `develop`/`feature`-Branches ok.

## GreyHack-Build-Pipeline
- Steam Native Linux. Ablauf: `pc.wget` → `shell.build` → `delete`.
- `greybel build` **ohne `-u`** kann *keine* Einzeiler-if (`if ... then BODY end if`) und keine
  Inline-if-Ausdrücke parsen → immer auf mehrzeilige `if/else/end if`-Blöcke ausschreiben.
- `import_code`-Bug: `lib_core` als `.src` einbinden.
- GreyScript-Eigenheiten: `0` ist truthy, `char(10)` für Newline, `is_binary` statt `is_folder`,
  kein `str_repeat`, kein HTTP, keine negativen Indizes.

## Modell-Routing (siehe config/config.yaml)
- Heartbeat/Routine → billiges Modell.
- Alltag → günstig-aber-gut.
- Coding/komplex → starkes Modell.
- Subagenten (Recherche) → billiges Modell.

## Workarounds-Log
- (leer — hier neue Tool-Quirks eintragen, sobald sie auftauchen)
