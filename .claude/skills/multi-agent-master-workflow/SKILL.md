---
name: multi-agent-master-workflow
description: 'Generisches Subagent/Master-Controller-Pattern für parallele Analyse-, Audit- und Umsetzungsaufgaben — mappt auf Hermes Queen/Worker/Gate. Use when the user sagt "prüfe systematisch", "analysiere und priorisiere" oder "erstelle einen umsetzungsplan" und keine Domain aus workflow-template passt. Für Domain-Aufgaben (Hardening, Repo/CI, CVE, GreyScript, Ollama) stattdessen den Domain-Adapter workflow-template nutzen.'
version: 1.2.0
author: Yuno for the user
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [workflow, orchestration, multi-agent, queen-worker-gate, planning]
    related_skills: [workflow-template, subagent-driven-development, critic-gate, delegation-anti-patterns]
    lane: koenigin
    reasoning_effort: high
---
# Multi-Agent Master Workflow

Master-Controller/Subagent-Pattern für systematische Analyse- und Umsetzungsaufgaben.
Dies ist das **Orchestrierungs-Pattern**; domänenspezifische Ausprägungen liefert der
Skill `workflow-template` (5 fertige Templates + Decision-Tree).

## Rollen (Mapping auf Hermes)

| Generisch | Hermes-Rolle | Aufgabe |
|---|---|---|
| Subagent A–E (3–6, parallel) | Worker | Je ein abgegrenzter Scope; Output: Kurzbefund, Lücken/Probleme, Verbesserungsvorschläge, Priorität, markierte Annahmen |
| Master-Controller | Queen | merge_results, deduplicate, resolve_conflicts, unify_priorities, decompose_into_tasks, define_execution_order |
| QA-/Abnahmeprüfung | Gate | Vollständigkeit, Konsistenz, Nachvollziehbarkeit, Risiken benannt — **verpflichtend** bei Security, Produktionscode, öffentlicher Doku |

## Phasen

0. **Vor-Inventur (Baseline Build)** — Vor jedem Dispatch: CI-Build laufen lassen (`bash scripts/ci-build.sh 2>&1 | grep FAIL`). Die Baseline-Fail-Liste dokumentieren. Später gegen Endzustand vergleichen — Coverage-Gap Detection. Ohne Phase 0 sind pre-existing Fails unsichtbar im Pattern-Rauschen.

1. **Inventarisierung** — Elemente erfassen, Kategorien zuordnen
2. **Analyse** — je Element: behalten | überarbeiten | neu | teilen | zusammenführen | entfernen
3. **Priorisierung** — kritisch | hoch | mittel | niedrig (🟥🟧🟨🟩)
4. **Umsetzung** — je Maßnahme: Titel, Kategorie, Begründung, Dringlichkeit, Aufwand (S/M/L), Abhängigkeiten
5. **QA/Gate** — Gate-Prüfung vor Freigabe

## Constraints

- Keine unbelegten Annahmen; jede Empfehlung beruht auf einem konkreten Befund
- Bei Unsicherheit markieren statt raten
- Kleine, reviewbare Schritte — keine Monolithen
- Gib nur das Ergebnis aus (kein Preamble)

## Domain-Spezifisch: Cross-Repo GitHub Cleanup

Bewährtes Dispatch-Pattern aus der M3 Bienen-Schwarm-Session (2026-07-07) für
"Geh alle offenen GitHub-Issues/PRs an" über 3+ Repos.

### Dispatch-Strategie

```
Welle 1 (3 Subagenten, parallel — unabhängige Repos):
  Biene A: Repo-1 — alle PRs + Issues
  Biene B: Repo-2 — das gleiche
  Biene C: Repo-3 — das gleiche

Welle 2 (nach Welle-1-Ergebnissen, 1–3 Subagenten):
  Biene D: merge_results + deduplicate + resolve_conflicts
  Biene E: feature-assessment (Security, Planning, Roadmap)
  Biene F: cross-repo issues (Tracking-Items, DMZ-Referenzen)
```

### Dispatch-Scope Verification (vor Aufruf von delegate_task)

**File-Affinity Check (Anti-Pattern #10):** Jede Datei darf max. EINEM Subagenten zugeordnet sein. Überlappungen = Königin macht es selbst (Parent-Direct, sequenziell).

```python
from collections import defaultdict
file_to_agents = defaultdict(list)
for agent, files in assignments.items():
    for f in files:
        file_to_agents[f].append(agent)
overlap = {f: a for f, a in file_to_agents.items() if len(a) > 1}
# → remove overlaps from all subagent lists, queen does them
```

**Baseline-Build Pre-Check (Anti-Pattern #9):** `bash scripts/ci-build.sh 2>&1 | grep FAIL` vor Dispatch — sonst sind pre-existing Fails unsichtbar.

**Report-Template Pre-Create (Anti-Pattern #11):** `write_file("/tmp/report-<agent>.md", "# <Agent>\n## Files\nNone yet\n## Build\nNone yet")` **VOR** erstem Tool-Burst — sonst fehlt bei Truncation der Report.

**Pre-Push Check (Anti-Pattern #12):** `gh pr view <N> --json mergeable` + `git fetch origin main` VOR Force-Push. `--force-with-lease` statt `--force`.

### Subagent-Briefing-Template

```
Goal: Schließe alte/irrelevante PRs + Issues in {repo}.

Prioritätsordnung:
1. Dependabot-PRs → sofort close (keine Zeit mit Bodies verschwenden)
2. Offene PRs → reviewen: diff + name-only + stat checken
3. Issues zu geschlossenen PRs → close oder redirect
4. Restliche Issues → labeln + priorisieren

PR-CI-Artifact-Detection: `gh pr diff N --name-only | grep -cE
'(coverage/|\.html|\.js\.map|\.nyc_output/)'`
Wenn NUR CI-Artifakte: close als not_planned + .gitignore fixen.

Output: Liste geschlossener Items mit Begründung
```

### Pitfalls

| Fehler | Fix |
|--------|-----|
| Dependabot-Bodies lesen | Direkt schließen — verschwendet Token |
| PR-Lines als echter Code | `--name-only` checken. 6.885 Zeilen können alles coverage/ sein |
| .gitignore vergessen | JEDER CI-Artifact-PR-Close braucht .gitignore-Fix |
| Alle 6 Bienen gleichzeitig | 3 repo-spezifisch (parallel), dann in Welle 2 kreuzend dispatchen |
| Issue ohne Redirect schließen | In Kommentar: "Verschoben nach → {ziel}" |

## Ergebnisformat

Reihenfolge: Kurzfazit → Inventar → Gap-/Problem-Analyse → priorisierte Maßnahmen →
Umsetzungsworkflow → QA-Checkliste → offene Punkte.

Bei `[AGENT-MODE: AKTIV]`: striktes JSON-Schema
`{kurzfazit, inventar[], gap_analyse[], massnahmen[], workflow[], qa_checkliste[], offene_punkte[]}` — keine Erklärtexte.

## Quellen & Verwandtes

- Historische Specs (eingefroren): `~/Downloads/Github/{docs-refresh-master-workflow.md, master-workflow-ai-agenten-template.md, skill-multi-agent-master-workflow.yaml}`
- Source-of-Truth-Index: `~/Downloads/Github/master-workflow-overview.md`
- Domain-Adapter: `orchestration/workflow-template` (5 Templates, Mnemosyne-Hooks, Farb-Legende)
