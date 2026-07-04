# Block 5 — Automatisierung

## Ziel in einem Satz
MaxClaw proaktiv machen: mit Heartbeat (regelmäßiges Monitoring) und Cron-Jobs (feste Zeiten).

## Heartbeat — der Puls des Agenten
Ermöglicht MaxClaw, **von sich aus** aktiv zu werden. In einem festen Intervall
(**standardmäßig alle 30 Minuten**) weckt das Gateway den Agenten und fragt: „Gibt es etwas,
worum du dich kümmern musst?"

Der Agent liest dann die **HEARTBEAT.md** (im Workspace, standardmäßig fast leer) — eine
**Checkliste** an Aufgaben, die er periodisch abarbeiten soll. Z. B.:
- „Prüfe, ob ein wichtiger Termin bald ansteht, und erinnere mich vorher."
- „Prüfe, ob Website X einen neuen Blogartikel veröffentlicht hat, und gib Bescheid."

Steht nichts an, antwortet der Agent intern nur „Heartbeat OK" — das Gateway **unterdrückt**
diese Antwort, du bekommst nichts. Alles läuft still im Hintergrund.

> ⚠️ **Jeder Heartbeat ist ein API-Call** — und lädt *alle* Core-Dateien (z. B. 10.000 Tokens),
> auch wenn nichts ansteht! Deshalb:
> - **Günstiges Modell** für den Heartbeat nutzen.
> - Nur Dinge in HEARTBEAT.md legen, die wirklich alle 30 min gecheckt werden müssen.

## Cron-Jobs — geplante Aufgaben zu festen Zeiten
Der Name kommt von *Chronos* (Gott der Zeit). Ein Cron-Job läuft **automatisch zu einem
definierten Zeitpunkt**. Beispiele:
- tägliches Briefing um 07:00
- Security-Audit jeden Montag 09:00
- Social-Media-Repost jeden Freitag Nachmittag

Einrichten? Einfach sagen: „Ich will jeden Morgen um 7 Uhr ein Briefing." — MaxClaw richtet es ein.

## Heartbeat vs. Cron — wann was?

| | Heartbeat | Cron-Job |
|---|-----------|----------|
| Zeitpunkt | alle 30 min gebündelt | fester, exakter Zeitpunkt |
| Zweck | Überwachung, „falls etwas ansteht" | „muss pünktlich passieren" |
| Beispiel | „gibt's neue Mails/Termine?" | „07:00 Briefing senden" |

> 💡 Auch Cron-Jobs sind API-Calls und kosten Tokens. Überleg gut, was Heartbeat und was Cron sein soll.

## Unsere konkreten Workflows (siehe [`../workflows/`](../workflows/))

| Workflow | Typ | Takt | Deliver | Zweck |
|----------|-----|------|---------|-------|
| `daily-briefing` | Cron | tägl. 07:00 | telegram | Kompaktes Briefing per Telegram |
| `greyhack-ci-watch` | Cron | stündl. | telegram | greybel-Build grün nach Commit? |
| `greyhack-tool-builder` | Cron | alle 2h | telegram | Sandbox-Refactoring, 1 Baustelle pro Lauf |
| `github-pr-monitor` | Cron | 09,17 | telegram | Offene PRs/Issues Toqsick-Repos |
| `greyhack-db-snapshot` | Cron | alle 6h | telegram | DB-Sandbox-Clone + Größen-Diff |
| `greyhack-db-watcher` | Cron | */30 min | telegram | DB-Inhalt-Diff (Computer, Mails, Bänke) |
| `greyhack-mission-tracker` | Cron | alle 4h | telegram | Brief ↔ MISSION-LOG synchronisieren |
| `greyhack-tool-backup-watch` | Cron | alle 6h | local | Dirty-Tree + 3-Tage-Push-Frist |
| `greyhack-knowledge-distiller` | Cron | So 22:00 | local | Wochen-Synthese → `~/docs/system/greyhack-weekly-insights-*.md` |
| `greyhack-basti-checkin` | Cron | Mo/Mi/Fr 20:00 | telegram | Kumpel-Anstoß, max. 12 Zeilen |
| `security-audit-weekly` | Cron | Mo 09:00 | telegram | Read-Only-Audit Desktop + VM |

(v3.0: **8 neue Crons** hinzugekommen — siehe `WORKFLOWS-V2-2026-07-04.md`)

Registrieren: `./workflows/register-workflows.sh [--add NAME | --list | --dry-run]`

### Skills als Cron-Backbone (v3.0)

Jeder neue Cron sollte **einen Skill nutzen** statt Freitext-Prompts. Vorteile:
- Prompt wird zwischen Sessions portierbar (git-versioniert)
- Tests möglich (skill-view → Validierung der YAML-Frontmatter)
- Andere Agents im Multi-Agent-Setup können denselben Skill lesen

Workflow z.B.: `greyhack-db-watcher` lädt `sandbox-snapshot` + `sqlite-reader`. Beide Skills
sind in v3.0 in [`../skills/`](../skills/) definiert und via [`../skills/INSTALL.md`](../skills/INSTALL.md)
installierbar.

## Häufige Fehler
- ❌ Teures Hauptmodell für den Heartbeat → Tokens verbrennen für „nichts".
- ❌ Zu viele Checks in HEARTBEAT.md → alle 30 min teuer.
- ✅ Billiges Modell + minimale, wirklich nötige Checks.

## Nächste Ausbaustufe
→ [Block 6 — Erweiterungen](06-erweiterungen.md)
