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

| Workflow | Typ | Zeitpunkt | Zweck |
|----------|-----|-----------|-------|
| `daily-briefing` | Cron | tägl. 07:00 | Kompaktes Briefing per Telegram |
| `greyhack-ci-watch` | Cron | nach Push / stündl. | greybel-Build grün? |
| `security-audit-weekly` | Cron | Mo 09:00 | Read-Only-Audit Desktop + VM |
| `github-pr-monitor` | Cron | 2×/Tag | Offene PRs/Issues Toqsick-Repos |

Registrieren: `./workflows/register-workflows.sh`

## Häufige Fehler
- ❌ Teures Hauptmodell für den Heartbeat → Tokens verbrennen für „nichts".
- ❌ Zu viele Checks in HEARTBEAT.md → alle 30 min teuer.
- ✅ Billiges Modell + minimale, wirklich nötige Checks.

## Nächste Ausbaustufe
→ [Block 6 — Erweiterungen](06-erweiterungen.md)
