---
name: system-documentation
title: System & Project Documentation
description: >-
  Maintain a structured Markdown documentation tree for all system builds, fixes, configurations, and project changes. Gives the user a browsable system overview with context for every change we make.
triggers:
  - User asks for "Dokumentation" or "Systemübersicht" or "Dokumentation zu allem was wir machen"
  - User wants to track what was built, fixed, or configured over time
  - User says "schreib mal auf was wir gemacht haben"
  - After completing a system change, fix, or build (always offer to document it)
  - Starting a new project or system modification
  - User mentions Obsidian Vault, "Vault aufsetzen", "8-Ordner", Julian Ivanov, Dataview, MOC
  - User says "befülle den Vault" / "schreib das in Obsidian" / "dokumentiere das in Vault"
version: 1.1.0
author: Hermes Agent
changelog:
  - 2026-07-05 - Obsidian-Vault-Modus (Julian-Ivanov-8-Ordner) als the user's bevorzugte Doku-Stätte seit 2026-07-05
  - 2026-07-05 - Dataview-Plugin-Hinweis in Obsidian-Modus integriert
  - 2026-07-05 - Mnemosyne-ID-Referenz-Konvention für Vault-Notes etabliert
license: MIT
lane: koenigin
reasoning_effort: xhigh
agent: Writer
routing_hint: |
  **Agent-Scope:** Long-form content, docs, proposals, copy. Off-scope: code, design, data modeling — return to Yuno.
  
  Routing-Spec: `yuno-team-routing`.
  
---
# System & Project Documentation

## Purpose

Keep a living document tree of everything built or fixed on the user's system.
Each entry captures: goal, approach, exact commands, file paths changed, results,
and decision rationale. This makes future sessions self-sufficient — no need to
re-discover what was done or why.

## Directory Structure

All docs live under a central directory. Use the location the user prefers;
default is `~/docs/system/` if no preference is given.

**the user's preferred structure (shallow, flat):**

```

set -euo pipefail
~/docs/
├── system/
│   ├── README.md          # System-Übersicht (Specs, Pfade, Cleanup-Log)
│   └── security.md        # Sicherheits-Audit (Ports, Dienste, Fixes)
├── builds/
│   └── README.md          # Projekte + Tools (sysdoctor, greysync, gmail-organizer)
└── scripts/
    └── (frei für Script-Doku)
```

Alternative deep tree (use if user has many docs or asks for more structure):

```

set -euo pipefail
~/docs/system/
├── README.md                # Index with links to all entries
├── 01-hardware/
│   └── monitor-setup.md     # EDID fix, custom modelines, monitor configs
├── 02-software/
│   └── hermes-config.md     # Hermes Agent profiles, providers, cron jobs
├── 03-network/
│   └── monitor-edid.md      # EDID recovery, reduced-blanking timing
└── 04-maintenance/
    └── cleanup-workflow.md  # Systempflege steps: kernel, cache, logs
```bash
~/docs/system/
├── README.md                # Index with links to all entries
├── 01-hardware/
│   ├── monitor-setup.md     # EDID fix, custom modelines, monitor configs
│   ├── gpu-tuning.md        # NVIDIA PRIME, Dynamic Boost, GameMode hooks
│   └── cpu-governor.md      # intel_pstate EPP vs governor quirks
├── 02-software/
│   ├── hermes-config.md     # Hermes Agent profiles, providers, cron jobs
│   ├── steam-setup.md       # GameMode, start-options, shader cache notes
│   └── greyhack-tools.md    # GreyScript Arsenal — lib_core, import paths, user name
├── 03-network/
│   └── monitor-edid.md      # EDID recovery, reduced-blanking timing
├── 04-maintenance/
│   ├── cleanup-workflow.md  # Systempflege steps: kernel, cache, logs
│   └── backup-notes.md      # What gets backed up and how
└── 05-projects/
    └── greyhack-arsenal.md  # Full toolset overview, version history
```

set -euo pipefail
> For the user: he uses `~/docs/system/README.md` (system overview) + `~/docs/system/security.md` + `~/docs/builds/README.md` (projects/tools). Flat files, shallow structure. Offer this format unless he asks for more nesting.

## Obsidian-Vault-Modus (the user seit 2026-07-05)

the user hat einen Obsidian-Vault unter `~/Dokumente/Obsidian Vault/` parallel zu `~/docs/`. Der Vault nutzt Julian-Ivanov-8-Ordner-Struktur und ist seit 2026-07-05 **die bevorzugte Doku-Stätte** für neue Builds/Fixes/Konfigurationen — nicht mehr `~/docs/`.

**Welches System nehmen?**

| Wenn ... | Dann nutze ... |
|---|---|
| Notiz ist projektspezifisch (Build/Fix mit Zielbild+Ende) | Obsidian Vault: `03 Projekte/<name>/` |
| Notiz ist dauerhafter Lebensbereich (Gaming, Dev, System...) | Obsidian Vault: `04 Bereiche/<bereich>.md` |
| Notiz ist Hardware-Spec, Profil, Framework-Spiegel | Obsidian Vault: `01 Kontext/` |
| Notiz ist externe Ressource / How-to / Skript | Obsidian Vault: `05 Ressourcen/` |
| Tagesjournal / Daily-Note | Obsidian Vault: `06 Daily Notes/` |
| User fragt explizit nach "~/docs/" oder hat keinen Vault | legacy `~/docs/system/` weiter benutzen |

**Vault-Pfad-Resolution:** Vault liegt unter `~/Dokumente/Obsidian Vault/` (Zorin/Ubuntu deutsches Locales), NICHT `~/Documents/Obsidian Vault/` (eng) und NICHT `~/Documents/`. Immer prüfen via `ls -d` oder `find ~ -maxdepth 4 -type d -iname "*obsidian*"`.

**Vault-Befüllungs-Sequenz (wenn User "befülle den Vault mit allem was du weißt" sagt):**

1. **Ist-Zustand:** `find <vault> -type f -name '*.md' -not -path '*/.obsidian/*'` → Inventar
2. **8 Ordner anlegen:** `mkdir -p` mit führender Ziffer + Leerzeichen + Name (`01 Kontext`, `02 Inbox`, `03 Projekte`, `04 Bereiche`, `05 Ressourcen`, `06 Daily Notes`, `07 Archiv`, `08 Anhaenge`). Niemals ohne `-p`.
3. **`MOC - Home.md` in Vault-Root** mit Dataview-Queries (LIST from "..." SORT file.name ASC).
4. **Hardware-Snapshot** (`01 Kontext/Hardware - <chassis>.md`) — am wichtigsten, gründet alle anderen.
5. **Identitäts-Notes** (`01 Kontext/`): User-Profil, Agent-Identität, Working-Agreement, Framework-Spiegel.
6. **Bereiche** (`04 Bereiche/_MOC.md` + je eine Note pro Lebensbereich) — alle mit Dataview-Queries.
7. **Inbox-Vorlage** (`02 Inbox/<datum> - Inbox Setup.md`) für Quick-Pickup mit 7-Tage-Haltezeit.
8. **Projekt-Hauptthema CHANGELOG** um Befüllungs-Eintrag erweitern mit Mnemosyne-IDs.

**Mnemosyne-als-Source-of-Truth:** Vault-Notizen spiegeln Mnemosyne-Memories, sind aber NICHT die Quelle. Mnemosyne-Recall bleibt im Memory-Layer, Vault ist Browse-Layer für den User. Mnemosyne-ID als Referenz in Vault-Note hinterlassen, damit SOT-Kette klar ist.

**NICHT in Vault-Notes:** Commit-SHAs, PR-Nummern, Issue-Nummern, File-Counts, Branch-Namen — 7-Tage-stale, gehört in Mnemosyne working-tier, nicht in langlebige Notizen.

**Dataview-Plugin:** Pflicht für MOCs. MUSS manuell in Obsidian Settings → Community Plugins aktiviert werden. In Reply erwähnen, nicht in Note. Queries-Snippets stehen in der Frontmatter-Sektion "Dataview-Queries".

## Obsidian-Plugins Quick-Reference

| Plugin | Zweck |
|---|---|
| Dataview | Live-Datenbank-Abfragen (MOCs) — Pflicht |
| Templater | Vorlagen + Datum-Auto (Daily Notes) |
| Calendar | Kalenderansicht für Daily Notes |
| Periodic Notes | Periodische Notizen (täglich/wöchentlich) |
| Excalidraw | Hand-drawn Diagramme |
| Mindmap | Struktur-Karten aus Headings |
| Tasks | Task-Management mit Dataview-Integration |

## Entry Format

Every entry follows the same template:

```markdown
# Title

**Datum:** YYYY-MM-DD
**Kontext:** Session-Summary / Anlass

## Ziel

Was sollte erreicht werden?

## Vorgehen

1. Schritt 1 (Befehl / Ansatz)
2. Schritt 2
3. …

## Dateien & Pfade

- `~/some/path` → was wurde geändert
- `/etc/some/config` → Konfiguration

## Ergebnis

Was hat funktioniert, was nicht. Ggf. Screenshot/Log-Hinweise.

## Entscheidungen

Warum wurde Ansatz X statt Y gewählt? Welche Kompromisse?
```

set -euo pipefail
## GreyHack Project Documentation

For `~/greyscripts`, document both system-level build/fix context and research/spec context:

- System/build fixes go under `~/docs/system/`, e.g. `greyhack-p0-build-fixes-YYYY-MM-DD.md`.
- Research outputs go under `~/greyscripts/docs/security-research/`.
- Mini-specs go under `~/greyscripts/docs/security-research/specs/`.
- Mini-tool implementation reports go under `~/docs/system/`, e.g. `greyhack-mini-tools-implementation-YYYY-MM-DD.md`.
- Always record branch policy: P0 before P1-P4, feature branch from `develop`, never touch `main` without explicit approval.
- Include exact build commands and real Greybel outputs.
- Separate resolved P0 blockers from open later research/tool candidates.

## Documentation Triggers

After any of these actions, offer to document:

1. **System change** (kernel removal, package purge, config edit)
2. **Hardware fix** (monitor EDID, GPU tuning, fan curves)
3. **Build** (new toolset, script collection, CLI project)
4. **Config migration** (hermes config, Thunderbird/Evolution, cron jobs)
5. **Debugging path** (something that took >5 steps to resolve)
6. **Cron delivery issue** (timeout, missing script, delivery_error)
7. **TypeScript/JS project fix** (tsc errors, jest failures, build fixes)

## Hermes V7 Project Documentation

For `~/hermes-zorin` (Branch: `Zorin-Hermes-alt` → `origin/Zorin-Hermes-alt`):

- **Build:** `npx tsc --noEmit` (type check) → `npx tsc` (build to `dist/`)
- **Test:** `npm run test` (jest, konfiguriert aber 0 tests)
- **Live-Test:** `node depp-live-test.js` (benötigt `OPENROUTER_API_KEY`)
- **Import-Convention:** `.js`-Suffixe in Imports (ESM-Style) → nur via `tsc`→`node dist/` ausführbar, NICHT via ts-node
- **Root:** `rootDir: "."` (wegen `cli/` + `src/`)

See: `references/typescript-build-pitfalls.md` for full error transcripts and fixes.

## TypeScript Project Documentation

For TypeScript/Node.js projects (like `~/hermes-zorin`), document:

- Build command: `npx tsc --noEmit` (type check) or `npm run build`
- Test command: `npm run test` (jest)
- LSP diagnostics: `npx tsc --noEmit 2>&1 | head -50`
- Common error patterns: type narrowing, duplicate modules, import path mismatches
- Fix verification: always re-run `tsc --noEmit` after fixes

### TypeScript Pitfalls (from hermes-zorin V7 development)

1. **`.js` Import-Suffixe + CommonJS**: `module: commonjs` + `.js`-Imports → ts-node kann Module nicht auflösen. Fix: `npx tsc` → `node dist/` ODER Imports ohne Suffix
2. **Type Narrowing in Compound Conditions**: TS narrows types after first check — extract to variables first
3. **Verdict vs Signal Type Confusion**: Don't compare against enum A when checking enum B
4. **Duplicate Module Detection**: `diff file1 file2` — if identical, delete the one with broken import paths. Nach Löschen: `rm -rf dist && npx tsc`
5. **Implicit `any` Cascade**: Fix the missing import, don't add `: any`
6. **rootDir Mismatch**: `rootDir` muss alle included Dateien enthalten (inkl. `cli/`)

Siehe auch: `references/typescript-build-pitfalls.md` für vollständige Session-Traces.

## Repository Documentation Maintenance

For maintaining README, CHANGELOG, ROADMAP, NAVIGATION, and cross-references in **GitHub project repos** (e.g. `~/greyhack-tools/`).

### Workflow

1. **Inventory** — Collect all `.md` files (exclude `backups/`, `.git/`, `de/`): `find . -name "*.md" -not -path "./backups/*" -not -path "./.git/*" | sort`
2. **Dead-link scan** — Use `search_files(target='content', pattern='...')` to find stale references across the whole repo
3. **Audit cross-links** — Check that files reference each other (README links to CHANGELOG, NAVIGATION links to README, etc.)
4. **Verify numbers** — Count actual artifacts (`.src` files, tool directories) and compare against claims in meta-docs
5. **Apply fixes** — Use `patch` for targeted edits across multiple files
6. **Verify** — Write a temporary verification script in `/tmp/hermes-verify-*.py` that checks:
   - Dead links (e.g. `docs/CHANGELOG.md` → `CHANGELOG.md`)
   - Date ordering in CHANGELOG (newest first)
   - Cross-references between README/CHANGELOG/ROADMAP
   - Actual file counts match doc claims
7. **Cleanup** — Remove verification script after run

### Key commands for repo doc maintenance

```bash
# Find all broken references
search_files(target='content', pattern='docs/CHANGELOG\\.md', path='~/repo/')

# Count actual files (exclude backups, .git)
find . -name "*.src" -not -path "./backups/*" -not -path "./.git/*" | wc -l

# Verify all cross-references
# Write a focused Python script to /tmp/ and run it
```

set -euo pipefail
### Common fixes

| Problem | Fix |
|---------|-----|
| Moved file, dead link | `patch(old_string, new_string)` with exact paths |
| Outdated counts | Re-scan repo and update all affected docs |
| Missing file reference | Add link to Quick-Links or table of contents |
| CHANGELOG dates out of order | Regex `^## (\d{4}-\d{2}-\d{2})` and sort |

See `references/repo-doc-workflow.md` for a full session trace.

## Language Conventions

- **Write in German** unless the user explicitly asks for English
- Be specific with **exact file paths** and **exact commands run**
- Include the **error messages** that were encountered and how they were resolved
- Keep entries **browseable** — use headings, tables, and code blocks
- Link between related entries (e.g., "siehe auch GPU-Tuning")

## User Preference: the user

- the user wants detailed docs ("mehr Tiefe, nicht Quick-and-Dirty")
- Prefers CLI-level precision: exact commands, full paths, no hand-waving
- Docs are for **cross-session context** — so a new model after a switch can
  get up to speed immediately

## README.md (Index File)

Maintain a README.md that serves as the table of contents:

```markdown
# System-Dokumentation

Übersicht aller dokumentierten Builds, Fixes und Konfigurationen.

## Hardware
- Monitor EDID Fix — Acer XB240H, reduced-blanking
- GPU & Gaming — RTX 5060, GameMode Hooks
- CPU Tuning — intel_pstate, EPP, powerprofilesctl

## Software
- Hermes Config — Profile, Providers, Cron
- Greyhack Tools — the user's Arsenal v2.0

## Maintenance
- Cleanup Workflow — Regelmäßige Systempflege

## Projekte
- Greyhack Arsenal — 12 GreyScript Tools
```

Update the README.md every time a new entry is added so it stays current.

## Pitfalls

1. **Don't duplicate memory.** Memory captures who the user is and what's stable.
   Documentation captures *what changed* and *how*. If it's a procedural how-to
   that will be reused, it belongs here as a doc entry.
2. **Don't duplicate skills.** Skills capture *how to do something* for the agent.
   Documentation captures *what was done* for the user. Different audiences.
3. **Keep docs shallow.** Max 3 levels of nesting (`01-hardware/`, not
   `01-hardware/01-gpu/02-nvidia/03-rtx-5060/…`).
4. **Offer, don't force.** After a change, ask: "Soll ich das dokumentieren?"
   Let the user decide.
5. **Never document secrets.** API keys, passwords, tokens, or personal emails never go into the doc tree. Use memory or env vars instead.
6. **If a secret was pasted in chat:** do not transcribe the value into documentation. Document only that the secret was treated as exposed, rotation was recommended, and no value was stored.
7. **Docker backend: Repo paths don't exist in the container.** When the agent runs in Docker terminal backend (`terminal.backend: docker`), all file tools operate inside the container — not on the host. If the user references a host repo path like `~/my-project`, `cd`/`read_file`/`search_files` will fail with "No such file or directory". Do NOT retry the same path, guess contents, or fabricate results. Instead: (a) ask the user to mount the repo into the container with `-v`, (b) ask for `docker cp` of specific files, or (c) provide the fix as a patch the user applies on the host. Early detection: if `ls /home/` shows only `pn` (not the user's real home), you're in an isolated backend — adapt immediately.


## Event-Tracking mit Cron-Updates

Für Multi-Day-Events (Esports-Turniere, Sport-Events, Konferenzen) das Muster:
Schedule-Doc anlegen → täglichen Update-Cron → Archive-Cron nach Event-Ende.

Details in `references/event-tracking-workflow.md`:
- Workflow: initialer Schedule → Update-Cron → Archive-Cron
- Live-Score-Quellen: Liquipedia, HLTV, Polymarket (bester Fallback)
- Cron-Prompt-Aufbau, Pitfalls (Zeitzonen, Truncation, Badges)

## Multi-Agent Deep Research Docs

For sessions that spawn parallel research experts (3+ agents), use the
enhanced template in `references/deep-research-template.md`:

- **Master-Bericht** — Full research results + fixes + roadmap
- **Retrospektive** — What worked, what didn't, metrics, improvements
- **README-Update** — Index entry linking to both

This produces a 3-document set per research round instead of a single flat file.
