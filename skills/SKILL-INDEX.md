# MaxClaw Allround Skill-Set — Index & Decision-Tree

Schnellübersicht aller 8 Skills mit **Trigger-Keywords** für die automatische
Auswahl und einem **Decision-Tree**, der zeigt, wann welcher Skill greift.

## Skill-Index-Tabelle

| Skill                    | Kategorie       | Primäre Trigger-Keywords                                                  | Liefert                                              |
|--------------------------|-----------------|---------------------------------------------------------------------------|------------------------------------------------------|
| **sandbox-snapshot**     | filesystem      | `snapshot`, `backup`, `restore`, `rsync`, `pre-mutation`, `hardlink`      | rotierende Snapshots + Diff-Engine                   |
| **sqlite-reader**        | data            | `sqlite`, `.db`, `schema`, `pragma`, `foreign_key`, `read-only`, `analyse`| Schema-Inspiration + FK-Discovery + SELECT-Wizard    |
| **greyscript-linter**    | code            | `greybel build`, `*.src`, `//command:`, `pre-commit`, `static analysis`   | Static-Lint vor greybel-Build                        |
| **github-ops**           | collaboration   | `gh pr`, `gh issue`, `triage`, `conflict`, `rebase`, `monitor`, `review`  | PR-Erstellung, Issue-Triage, Conflict-Resolution     |
| **bash-script-builder**  | code            | `bash`, `set -euo pipefail`, `cron`, `helper`, `template`, `shellcheck`   | Boilerplate-Generator + Lint                         |
| **telegram-notifier**    | comms           | `telegram`, `notify`, `alert`, `silent`, `bot api`, `watchdog`, `summary` | Markdown→HTML-Notifier mit Watchdog-Modus             |
| **knowledge-distiller**  | meta            | `distill`, `weekly review`, `reflektion`, `skill-update`, `cluster`       | Wochenrückblick + Skill-Update-Vorschläge            |
| **maxclaw-session-manager** | workflow     | `session`, `tracking`, `lock`, `duplicate`, `cooldown`, `history`         | JSONL-Session-Log + Duplicate-Detection              |

## Decision-Tree (Wann welches Skill?)

```
Start: Was möchtest du tun?
│
├── Datei/Verzeichnis sichern oder wiederherstellen
│   └── sandbox-snapshot
│
├── Beliebige .db analysieren (GreyHack, Hermes, Tool-State)
│   └── sqlite-reader  (IMMER mode=ro + immutable=1)
│
├── GreyScript-Quelle schreiben/bauen
│   ├── Schreiben      → bash-script-builder (für Helper-Wrapper)
│   ├── Vor dem Build  → greyscript-linter
│   └── Nach dem Build → github-ops (PR erstellen)
│
├── Cron-Job / neues Bash-Skript anlegen
│   ├── Boilerplate    → bash-script-builder
│   ├── Tracking/Lock  → maxclaw-session-manager
│   └── Benachrichtigung → telegram-notifier (watchdog.sh)
│
├── Repo-/PR-Aktion auf GitHub
│   └── github-ops
│
├── Wochenrückblick / "Was läuft in MaxClaw?"
│   └── knowledge-distiller  (cron So 23:00)
│
└── Nachricht an Basti
    └── telegram-notifier  (info | ok | alert | summary)
```

## Trigger-Mapping (für automatische Skill-Auswahl)

| Aufgabe                                   | Primärer Skill                | Sekundäre Skills                       |
|-------------------------------------------|-------------------------------|----------------------------------------|
| GreyHack-DB vor Build sichern             | sandbox-snapshot              | greyscript-linter                      |
| GreyHack-Player-DB inspizieren            | sqlite-reader                 | —                                      |
| `greybel build` aus Cron triggern         | greyscript-linter             | github-ops, sandbox-snapshot           |
| PR nach erfolgreichem Build öffnen       | github-ops                    | telegram-notifier                      |
| Neues Helper-Skript anlegen               | bash-script-builder           | maxclaw-session-manager                |
| Cron-Output per Telegram                 | telegram-notifier             | maxclaw-session-manager                |
| Sonntags-Rückblick posten                 | knowledge-distiller           | telegram-notifier                      |
| "War MaxClaw schon mal aktiv?"            | maxclaw-session-manager       | —                                      |
| Konflikt in PR lösen                      | github-ops                    | sandbox-snapshot (vor Force-Push)      |

## Abdeckungs-Matrix (Zielgruppen)

| Zielgruppe                  | Skills                                                                       |
|-----------------------------|------------------------------------------------------------------------------|
| (a) GreyHack-Operations     | sandbox-snapshot, sqlite-reader, greyscript-linter, github-ops               |
| (b) System-Administration   | sandbox-snapshot, bash-script-builder, sqlite-reader                         |
| (c) Git/GitHub              | github-ops, bash-script-builder                                              |
| (d) Communications          | telegram-notifier, knowledge-distiller                                       |
| (e) Knowledge Management    | knowledge-distiller, maxclaw-session-manager                                 |

Jede Zielgruppe hat **mindestens 2 Skills**, die abwechselnd oder kombiniert
genutzt werden.

## Workflow-Beispiel: GreyHack-Tool v2 Release

```text
1. knowledge-distiller (Sonntag)     → schlägt "mehr greybel-Builds" vor
2. bash-script-builder               → neues build-pipeline.sh
3. maxclaw-session-manager (start)   → lock "build-pipeline"
4. sandbox-snapshot (pre-mutation)  → snapshot des Tool-Repos
5. greyscript-linter                 → *.src lint OK
6. greybel build                     → erzeugt Artefakt
7. maxclaw-session-manager (finish)  → log "build-pipeline OK"
8. github-ops                        → PR öffnen
9. telegram-notifier (ok)            → "✅ build-pipeline in 42s" (silent)
10. knowledge-distiller (nächster So) → merged das in "gelernt: pre-build snapshot"
```

## Maintenance

- **Skill-Update triggern**: nach jedem Fehler in einem Skill-Flow →
  Wissen landet im nächsten `knowledge-distiller`-Lauf und produziert
  Pitfall-Ergänzungen.
- **Versionierung**: jede Änderung am SKILL.md → `version:` im Frontmatter
  inkrementieren.
- **Validierung**: `python3 -c "import yaml; yaml.safe_load(open('SKILL.md').read().split('---')[1]))"`
  prüft das Frontmatter.