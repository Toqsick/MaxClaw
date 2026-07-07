# Workflow: GreyHack Knowledge-Distiller

**Typ:** Cron-Job (LLM, schwer) · **Zeitpunkt:** Sonntag 22:00 · **Modell:** `heavy` (Opus/Codex — Synthese) · **Deliver:** Datei + Telegram-Zusammenfassung · **Skills:** `skill-navigator`, `multi-agent-orchestration`, `greyhack`

## Ziel
MaxClaw destilliert **einmal pro Woche** die Cron-Outputs, Session-Logs und Skill-Fundstücke der
letzten 7 Tage zu einer kompakten **Weekly Insights-Notiz**. So entsteht ein wachsendes Gedächtnis
über Patterns, Stolperfallen und neue Erkenntnisse — ohne dass Basti es manuell pflegen muss.

## Warum?
Die GreyHack-Tools entwickeln sich ständig weiter, neue Bug-Patterns tauchen auf, alte Tools
werden deprecated. Ohne Distillierung verschwindet das Wissen in den Logs. Sonntag 22 Uhr ist
bewusst spät: Basti ist nicht am Spielen, die Woche ist abgeschlossen, der Agent hat das
Material frisch.

## Was passiert pro Lauf
1. **Inputs sammeln:**
   - `~/.local/share/openclaw/logs/*.log` der letzten 7 Tage
   - `~/greyhack-tools/MISSION-LOG.md` (Einträge der Woche)
   - `~/.openclaw/skills/gaming/greyhack/references/bug-patterns-*.md` (Änderungen seit letztem Lauf)
   - Cron-Output-Archive (`~/.local/share/maxclaw/cron-output/`)
2. **Vor-Clustering:** nach Themen clustern (Build-Issues, Game-Mechanik, Tool-Architektur, Workflow-Insights).
3. **Synthese (LLM-Call):** pro Cluster 2–4 Bullet-Points mit „Erkenntnis + Beleg + Konsequenz".
4. **Output schreiben:** `~/docs/system/greyhack-weekly-insights-YYYY-MM-DD.md` mit klarer Struktur:
   - **Highlights** (3–5)
   - **Neue Patterns / Bugs** (mit Tool-Name + Repro)
   - **Offene Fragen / nächste Woche**
   - **Index:** welche Cron-Logs gelesen wurden (für Auditierbarkeit)
5. **Telegram:** Kurzfassung (Top-3 Highlights + Top-1 offene Frage) — mehr nicht.

## Prompt (self-contained)
```
Du bist der GreyHack Knowledge-Distiller. Lese die Inputs der letzten 7 Tage:
- ~/.local/share/openclaw/logs/*.log  (OpenClaw-Session-Logs, JSONL)
- ~/greyhack-tools/MISSION-LOG.md   (Spiel-Aktivität)
- ~/.openclaw/skills/gaming/greyhack/references/bug-patterns-*.md  (Skill-Updates)
- ~/.local/share/maxclaw/cron-output/  (Output-Archive aller Crons der Woche)

Aufgaben:
1. Cluster die Erkenntnisse in 4 Buckets:
   a) Build-/Compiler-Insights (greybel, GreScript)
   b) Game-Mechanik (NPC-Verhalten, Bank-/Mail-Server-Patterns)
   c) Tool-Architektur (Library-Patterns, Refactoring-Möglichkeiten)
   d) Workflow-Insights (Cron-Erfolge, false positives, Bottlenecks)
2. Pro Cluster: max. 4 Bullet-Points im Format
   "**Insight** — Beleg (Quelle:Datei:Zeile) — Konsequenz (was ändert sich)".
3. Schreibe die Markdown-Notiz nach
   ~/docs/system/greyhack-weekly-insights-YYYY-MM-DD.md (YYYY-MM-DD = heutiges Datum).
   Struktur: # GreyHack Weekly Insights — <KW>
            ## Highlights (3–5)
            ## Neue Patterns / Bugs
            ## Offene Fragen / nächste Woche
            ## Quellen-Index
4. Schicke Basti per Telegram: nur die Highlights-Sektion + 1 wichtigste offene Frage (max. 8
   Zeilen). Wenn die Woche leer war (keine Crons, keine Logs): antworte "week quiet" und
   schicke NICHTS — überspringe auch das File-Write.

Nutze die Skills `skill-navigator` (zum Auffinden relevanter Skill-Refs), `multi-agent-orchestration`
(falls du 2–3 Subagenten parallel für Cluster-Analyse spawnen willst), `greyhack` (Domänen-Kontext).
Deutsch.
```

## Einrichten
```bash
#   Schedule: "0 22 * * 0"     (Sonntag 22:00)
#   Deliver:  telegram:7222661188 + Datei ~/docs/system/greyhack-weekly-insights-<datum>.md
#   Skills:   skill-navigator, multi-agent-orchestration, greyhack
#   (registriert via ./workflows/register-workflows.sh)
```

## Pitfalls
- ❌ **Komplette Logs ins File kippen** → Insights, nicht Datenhalde. Strikt auf 4 Cluster
  + max. 4 Bullets pro Cluster begrenzen.
- ❌ **Jede Woche ein neues File ohne Cleanup** → alte Insights werden vergessen. Hinweis in
  den File-Header: „Wenn >12 Wochen: älteste archivieren nach `~/docs/system/archive/`".
- ❌ **LLM halluziniert Quellen** → das Format „Quelle:Datei:Zeile" erzwingt Selbst-Disziplin
  und macht Halluzinationen sichtbar.
- ✅ **Schweres Modell** — Synthese über 7 Tage Inputs erfordert Reasoning; Sonntag 22 Uhr ist
  außerhalb der Spielzeit, also Kosten akzeptabel.
- ✅ **Multi-Agent optional** — der Skill `multi-agent-orchestration` darf genutzt werden, wenn
  die Inputs zu umfangreich sind. Aber: sequenziell ist meist günstiger und deterministischer.
- ✅ **Telegram-Kurzfassung** — Basti liest am Sonntag-Abend nur die TL;DR; das volle File ist
  für später.