# GitHub Issues — Triage Patterns

Detailed guide for issue management that complements `SKILL.md`'s quick-reference. Covers read-only triage reports, the priority matrix, and tool-fallback chains.

## Two Flavors of Triage

| Phrase | Mode | Mutation rights |
|--------|------|-----------------|
| "kategorisieren", "priorisieren", "review", "audit", "status" | **Read-only** | None — produce a Markdown report |
| "label them", "close the empty ones", "assign owners", "fix labels" | **Mutating** | Add/remove labels, comment, close (with `state_reason`) |

**Default to read-only** when uncertain. Reviewer profiles, external auditors, and many project-management tasks explicitly forbid mutations. Note in the report footer whether the run was read-only so downstream readers know.

## The Triage Report Shape

A good triage report has 6 sections:

1. **Top-of-report discrepancy flag** — when the user's stated scope (count, focus area, time window) doesn't match actual API state, call it out immediately. E.g. "User asked for 54 issues; repo has 7 (47 closed via #41, #42 on 2026-06-28)."
2. **Per-issue table** — number, title (truncated), category (P0-Bug / P1-Roadmap / P2-Nice / P3-Stale), labels, priority, recommendation (implement / keep / close-not-planned / wait).
3. **Activity check** — `age_days` (created → now) and `stale_days` (updated → now). Flag anything beyond project threshold (commonly 14 or 30 days) as candidate for `close as stale`.
4. **Empty-body detection** — issues with only a CI-badge link, a placeholder title (`[BUG]`, `[WIP]`, `TODO`), or a body <100 chars are almost always leftovers. Recommend `state_reason=not_planned` with a short comment.
5. **Recommended execution order** — derived from dependency graph (CI before features, smaller upstream blockers first). Cross-reference the order with which sub-issues feed into which meta-issues.
6. **Summary by category** — a 3-column table with category, count, percentage. Lets the reader see the distribution at a glance.

## The Priority Matrix (adapt to project conventions)

| Priority | Category | Meaning | Typical action |
|----------|----------|---------|----------------|
| 🔴 **P0** | Bug (critical) | Blocks CI, production, or has explicit severity/escalation label | Implement immediately |
| 🟡 **P1** | Roadmap / Feature | Has acceptance criteria or ROADMAP.md reference, owner known | Schedule next sprint |
| 🟢 **P2** | Nice-to-have / Cleanup | Improves DX but not blocking | Backlog |
| ⚫ **P3** | Stale / Placeholder / Wontfix | Empty body, placeholder title, author abandoned, or marked wontfix | Close with `state_reason=not_planned` |

Adjust thresholds per project: stricter projects may treat everything without an owner as P3. Don't invent labels the project doesn't use; stick to existing `bug`/`enhancement`/`roadmap`/etc.

## Recommended Execution Order — Heuristic

When multiple issues are open, derive order from:

1. **Path-of-least-resistance first** — small, well-defined issues that unblock other work or close meta-issues. Often comes from sub-issue splits (e.g. owner comment in #31 says "Empfohlene Reihenfolge: #41 → #42 → #43").
2. **Critical-path dependencies first** — CI/infra issues that block feature work (#30 blocks everything depending on the build).
3. **Roadmap order** — Phase 1 before Phase 2 before Phase 3 (per ROADMAP.md). Same project, same phase order preserves momentum.
4. **High-impact bundles last** — issues that ship a tool + fix N bugs in one PR (e.g. #54 ships `parse-exploit-reqs` + 3 bug fixes); these benefit from accumulated context.

Document the order in the report. The user may override, but the default is useful.

## The `gh issue view --json` Trap — `number` is Always Missing

`gh issue view <N> --json title,body,labels,createdAt,...` strips `number` (and `repository`) from output. Common failure:

```python
d = json.loads(gh_issue_view_output)
print(d['number'])  # KeyError: 'number'
```

Two workarounds:

```python
# Workaround A — re-inject the known number
gh issue view 42 --json title,body,... > /tmp/issue_42.json
d = json.load(open("/tmp/issue_42.json"))
d = {"number": 42, **d}

# Workaround B — separate number list + dict join
gh issue list --json number,title > /tmp/nums.json
gh issue view 42 --json title,body,... > /tmp/issue_42.json
nums = {x['number']: x for x in json.load(open("/tmp/nums.json"))}
issue_42 = {**nums[42], **json.load(open("/tmp/issue_42.json"))}
```

**Verified 2026-07-07** on Toqsick/greyscripts triage (7 issues). Every per-issue read needed the workaround; the JSON `title`/`body`/`labels` were complete but `number` was always absent.

## MCP GitHub → `gh` CLI Fallback (Detailed)

Already covered in SKILL.md's "MCP GitHub vs gh CLI Fallback" section above. Triage-specific notes:

- **When the MCP `mcp__github__list_issues` returns 401 mid-task, don't retry — switch immediately to `gh`.** Retrying wastes context and produces the same error.
- **Save each issue's JSON to disk immediately:** `gh issue view <N> --json ... > /tmp/issue_<N>.json`. This decouples parsing from refetching and makes Python aggregations cheap.
- **For meta-issues with N sub-issues referenced in comments** (e.g. #31 referencing #41/#42/#43), fetch the sub-issues by reading the comment body, then verify each via `gh issue view <sub> --json state` to learn which are closed vs still open. Don't trust the comment's claim — it may be outdated.
- **Mention "via gh CLI, MCP returned 401"** in the report so the user knows the data path. The 401 itself may be a project-level fix that the user wants to make later.

## Verified Session Example

**Date:** 2026-07-07
**Repo:** Toqsick/greyscripts
**User ask:** "Issue-Triage für greyscripts: Alle 54 offenen Issues kategorisieren und priorisieren."
**Actual count:** 7 (others closed via #41, #42 on 2026-06-28)

**Path taken:**
1. `mcp__github__list_issues` → 401 Bad credentials
2. `gh issue list -R Toqsick/greyscripts --state open --limit 100 --json number,title,...` → 7 issues
3. Verified counts via `gh issue list --state all --limit 100 --json number,state` to confirm 19 closed vs 7 open
4. For each open issue: `gh issue view <N> --json title,labels,body,createdAt,updatedAt,author,comments,state > /tmp/issue_<N>.json`
5. Python aggregator (`/tmp/triage.py`): load each JSON, compute `age_days` + `stale_days`, build triage table
6. Wrote report to local file `~/Biene1-Triage/issue-triage-greyscripts.md` (no GitHub mutations)
7. Report included: 6-row table (3 P0-Bug + 3 P1-Roadmap + 1 P3-Stale), activity check (all <14 days stale), empty-body detection on #48, recommended execution order from owner comment in #31

**Gotchas hit:**
- `gh issue view --json` missing `number` — every per-issue read needed workaround (parser tried `d['number']`).
- User's count of "54" → actual 7 → discrepancy flagged at top of report, didn't proceed silently.
- Issue #48 (empty body, only CI badge) flagged for `state_reason=not_planned` — would otherwise be invisible as a placeholder.

**Skills at play:** `github-issues` (SKILL.md quick-reference), `github-workflow` (MCP-vs-gh fallback + umbrella).
