# Yuno Skills — Master-Cheatsheet (Claude Code)

**141 Skills**, dedupliziert, verteilt auf 7 Team-Agenten.
Jeder Agent liegt unter `.claude/agents/`, jeder Skill unter `.claude/skills/<name>/SKILL.md`.

## `engineer` — Builder · Full-Stack Code  (32 Skills)
*Code schreiben, bauen, fixen, refactoren, debuggen, Git/GitHub-Workflows, Dev-Tooling.*  
**Trigger:** build, fix, refactor, review code, debug, implement, ci, pull request, merge

- [`claude-coder`](skills/claude-coder/SKILL.md) — Implementation Engineer fuer the user's polyglotte Projektwelt unter ~/10-Projekte/10-active/. Kennt alle 7 Projekte (Go, Python, Dart/Flutter, CUDA, GreyScript, Node/JS) mit ihren Build- und Test-Pip…
- [`claude-coding-specialist`](skills/claude-coding-specialist/SKILL.md) — Senior Software Engineer fuer HARD Probleme auf the user's Workstation. Architektur-Design, Cross-Cutting Refactors, Subtle/Heisenbug Debugging, Concurrency, Algorithm-Heavy Implementation. Migrated a…
- [`claude-worker`](skills/claude-worker/SKILL.md) — Mechanical Execution Agent fuer the user's Workstation. Batch edits, find-and-replace, renames, known fix patterns wiederholen, file cleanup. Wenn das "was" schon entschieden ist und kein Design-Judgm…
- [`github-workflow`](skills/github-workflow/SKILL.md) — Complete GitHub workflow: authentication (HTTPS/SSH/gh CLI), PR lifecycle (branch, commit, open, CI, merge), code review (local and PR-level), issue management (create, triage, label, assign), reposit…
- [`plan`](skills/plan/SKILL.md) — Plan mode: write an actionable markdown plan to .hermes/plans/, no execution. Bite-sized tasks, exact paths, complete code.
- [`subagent-driven-development`](skills/subagent-driven-development/SKILL.md) — Execute plans via delegate_task subagents (2-stage review).
- [`systematic-debugging`](skills/systematic-debugging/SKILL.md) — '4-phase root cause debugging: understand bugs before fixing.'
- [`writing-plans`](skills/writing-plans/SKILL.md) — 'Write implementation plans: bite-sized tasks, paths, code.'
- [`antigravity-cli`](skills/antigravity-cli/SKILL.md) — "Operate the Antigravity CLI (agy): plugins, auth, sandbox."
- [`bash-script-audit`](skills/bash-script-audit/SKILL.md) — Proactive audit of bash scripts for bugs, security issues, dead code, and inconsistencies. Systematic inventory
- [`claude-code`](skills/claude-code/SKILL.md) — Delegate coding to Claude Code CLI (features, PRs).
- [`codebase-inspection`](skills/codebase-inspection/SKILL.md) — 'Inspect codebases w/ pygount: LOC, languages, ratios.'
- [`codex`](skills/codex/SKILL.md) — Delegate coding to OpenAI Codex CLI (features, PRs).
- [`coding-agents`](skills/coding-agents/SKILL.md) — Delegate coding tasks to autonomous AI coding agent CLIs — Claude Code, OpenAI Codex, GitHub Copilot CLI, and
- [`copilot-cli`](skills/copilot-cli/SKILL.md) — "Delegate coding to GitHub Copilot CLI (features, PRs, code review). Copilot CLI runs as an ACP-compatible agent via `copilot --acp --stdio` or in print mode via `copilot -p`."
- [`dev-tools`](skills/dev-tools/SKILL.md) — Developer tools — systematic debugging (4-phase root cause), test-driven development, code quality gates (critic-gate,
- [`git-clone-audit`](skills/git-clone-audit/SKILL.md) — Systematischer Vergleich zweier lokaler Klone desselben Git-Remotes. Branch-Inventar, Cross-Clone-Diff, Hygiene-Scan, CI-Vergleich, Build-Verifikation und gewichtete Master-of-Truth-Bestimmung. Rein r…
- [`github-branch-inventory`](skills/github-branch-inventory/SKILL.md) — Multi-repo branch staleness scans, branch inventory with last-commit dates, auto-delete heuristics, and bulk branch cleanup workflows. Load for "branch-cleanup-scan", "stale branches", "Branch-Inventa…
- [`github-code-review`](skills/github-code-review/SKILL.md) — 'Review PRs: diffs, inline comments via gh or REST.'
- [`github-grayhack-workflow`](skills/github-grayhack-workflow/SKILL.md) — Automatisiert GitHub Issues, Branches, PRs und Doku für greyscripts/GreyHack-Entwicklung nach dem lokalen GitHub-Guide.
- [`github-issues`](skills/github-issues/SKILL.md) — Create, triage, label, assign GitHub issues via gh or REST.
- [`github-pr-merge-readiness`](skills/github-pr-merge-readiness/SKILL.md) — 'Assess one or more open PRs for merge-readiness — CI diagnosis, scope hygiene, cross-PR conflict detection, and a structured MERGE/NEEDS-WORK/CLOSE verdict. Distinct from code review (which asks "is …
- [`github-pr-workflow`](skills/github-pr-workflow/SKILL.md) — 'GitHub PR lifecycle: branch, commit, open, CI, merge.'
- [`github-repo-management`](skills/github-repo-management/SKILL.md) — Clone/create/fork repos; manage remotes, releases.
- [`github-sweep-orchestration`](skills/github-sweep-orchestration/SKILL.md) — Multi-Agent Pattern für kompletten GitHub-Repo-Cleanup mit M3-Bienen — Recon, Wave Dispatch, Consolidation. Use when user says "manage mein github", "räum github auf", "was ist offen", or wants all op…
- [`node-inspect-debugger`](skills/node-inspect-debugger/SKILL.md) — Debug Node.js via --inspect + Chrome DevTools Protocol CLI.
- [`opencode`](skills/opencode/SKILL.md) — Delegate coding to OpenCode CLI (features, PR review).
- [`python-debugpy`](skills/python-debugpy/SKILL.md) — 'Debug Python: pdb REPL + debugpy remote (DAP).'
- [`spike`](skills/spike/SKILL.md) — Throwaway experiments to validate an idea before build.
- [`sse-frontend-patterns`](skills/sse-frontend-patterns/SKILL.md) — Battle-tested patterns for real-time browser dashboards using native EventSource / Server-Sent Events in vanilla
- [`vanilla-js-tdz-helper-first`](skills/vanilla-js-tdz-helper-first/SKILL.md) — Definiere $() / setText() / escapeHtml() immer als ALLERERSTES im script-Tag, vor state, vor funktionen die sie
- [`hermes-agent`](skills/hermes-agent/SKILL.md) — Configure, extend, or contribute to Hermes Agent.

## `researcher` — Finder · Deep Research  (8 Skills)
*Recherche, Quellensuche, Web-Scraping, Paper-Analyse, Wissenssynthese, OCR.*  
**Trigger:** find me, what's the latest, research, compare, look up, sources, paper

- [`arxiv`](skills/arxiv/SKILL.md) — Search arXiv papers by keyword, author, category, or ID.
- [`bioinformatics`](skills/bioinformatics/SKILL.md) — Gateway to 400+ bioinformatics skills from bioSkills and ClawBio. Covers genomics, transcriptomics, single-cell, variant calling, pharmacogenomics, metagenomics, structural biology, and more. Fetches …
- [`firecrawl-web`](skills/firecrawl-web/SKILL.md) — Web-Scraping, Screenshots, strukturierte Daten-Extraktion, Web-Search und Crawling via Firecrawl API. Nutzen bei aktuellen Web-Infos, URL-Scraping, Screenshots oder Framework-Dokumentation.
- [`llm-wiki`](skills/llm-wiki/SKILL.md) — Karpathy's LLM Wiki: build/query interlinked markdown KB.
- [`notebooklm-bridge`](skills/notebooklm-bridge/SKILL.md) — Drive Google's NotebookLM from Hermes via the `notebooklm-py` CLI as a grounded synthesis + memory layer — list/create notebooks, ingest sources (URL, PDF, YouTube, Drive, text), run cited Q&A, and ge…
- [`ocr-and-documents`](skills/ocr-and-documents/SKILL.md) — Extract text from PDFs/scans (pymupdf, marker-pdf).
- [`research-paper-writing`](skills/research-paper-writing/SKILL.md) — 'Write ML papers for NeurIPS/ICML/ICLR: design→submit.'
- [`research-tools`](skills/research-tools/SKILL.md) — Research tools — arXiv paper search, blog/RSS monitoring (blogwatcher), web archive research (Common Crawl/WARC), LLM Wiki knowledge base, and Polymarket prediction market queries. Covers academic, we…

## `designer` — Visual · UI/UX & Kreativ  (38 Skills)
*UI/UX, Web-Design, Diagramme, Bilder, Video, Audio/Musik, kreative Assets.*  
**Trigger:** design, landing page, logo, UI, UX, diagram, image, video, poster, art

- [`anime-design`](skills/anime-design/SKILL.md) — Professional anime/2D art style generation skill. Covers 14 sub-styles (modern Japanese anime/moe, retro cel-shading, shonen, shojo, Ghibli, Makoto Shinkai, Chinese xianxia/ink wash, modern Chinese an…
- [`architecture-diagram`](skills/architecture-diagram/SKILL.md) — Dark-themed SVG architecture/cloud/infra diagrams as HTML.
- [`claude-design`](skills/claude-design/SKILL.md) — Design one-off HTML artifacts (landing, deck, prototype).
- [`excalidraw`](skills/excalidraw/SKILL.md) — Hand-drawn Excalidraw JSON diagrams (arch, flow, seq).
- [`film-shot`](skills/film-shot/SKILL.md) — Professional film storyboard / film still / character card design skill. Covers six-dimension shot language (shot type / camera position / movement / lighting / emotion / time) + 8 visual styles (cybe…
- [`html-artifact`](skills/html-artifact/SKILL.md) — Build self-contained HTML files to explain, plan, or review.
- [`humanizer`](skills/humanizer/SKILL.md) — 'Humanize text: strip AI-isms and add real voice.'
- [`popular-web-designs`](skills/popular-web-designs/SKILL.md) — 54 real design systems (Stripe, Linear, Vercel) as HTML/CSS.
- [`ui-color-system`](skills/ui-color-system/SKILL.md) — Generate accessible color palettes (semantic + scale) with WCAG contrast checking for light/dark/high-contrast modes. AUTO-TRIGGERS when user asks for "color palette", "brand colors", "accessible colo…
- [`ui-design-system`](skills/ui-design-system/SKILL.md) — Generate a complete design system (tokens, colors, typography, spacing scale) as JSON/CSS variables from a brief. Trigger phrases: creative/ui, design, system. Converted from Hermes-Skill (Yuno's mast…
- [`ui-factory`](skills/ui-factory/SKILL.md) — Orchestrate the full UI-Factory chain (color-system → design-system → component-library → dashboard) for complex UI tasks. Use when user asks to "build a UI", "create a dashboard", "design an app", "m…
- [`anime-style-forge`](skills/anime-style-forge/SKILL.md) — Specialized in anime/2D/character stylization for image generation and conversion. Covers Japanese, Chinese, Korean, and Western art style families. Uses provenance analysis to trace reference images'…
- [`ascii-art`](skills/ascii-art/SKILL.md) — 'ASCII art: pyfiglet, cowsay, boxes, image-to-ascii.'
- [`ascii-video`](skills/ascii-video/SKILL.md) — 'ASCII video: convert video/audio to colored ASCII MP4/GIF.'
- [`blender-mcp`](skills/blender-mcp/SKILL.md) — Control Blender directly from Hermes via socket connection to the blender-mcp addon. Create 3D objects, materials, animations, and run arbitrary Blender Python (bpy) code. Use when user wants to creat…
- [`canvas`](skills/canvas/SKILL.md) — Canvas LMS integration — fetch enrolled courses and assignments using API token authentication.
- [`comfyui`](skills/comfyui/SKILL.md) — "Generate images, video, and audio with ComfyUI — install, launch, manage nodes/models, run workflows with parameter injection. Uses the official comfy-cli for lifecycle and direct REST/WebSocket API …
- [`creative-ideation`](skills/creative-ideation/SKILL.md) — Generate project ideas via creative constraints.
- [`creative-suite`](skills/creative-suite/SKILL.md) — Creative content generation — ASCII art/video, architecture diagrams, infographics, comic strips, pixel art,
- [`design-md`](skills/design-md/SKILL.md) — Author/validate/export Google's DESIGN.md token spec files.
- [`drama-soundtrack`](skills/drama-soundtrack/SKILL.md) — Drama original soundtrack creation assistant. Creates complete soundtrack suites for TV series, films, and short dramas, including character theme songs, opening themes (OP), ending themes (ED), and s…
- [`dynamic-poster`](skills/dynamic-poster/SKILL.md) — Dynamic poster / motion graphic creator for product marketing. Transforms brand assets (logo, product photos) into surreal short video posters using "impossible juxtaposition" — products in physics-de…
- [`heartmula`](skills/heartmula/SKILL.md) — 'HeartMuLa: Suno-like song generation from lyrics + tags.'
- [`image`](skills/image/SKILL.md) — "Invoke when a user shares a reference image and wants new images with the same \"feel\" — composition, color palette, lighting, style, or mood — but different content. Analyzes the image across 10 ae…
- [`manim-video`](skills/manim-video/SKILL.md) — 'Manim CE animations: 3Blue1Brown math/algo videos.'
- [`p5js`](skills/p5js/SKILL.md) — 'p5.js sketches: gen art, shaders, interactive, 3D.'
- [`pixel-art`](skills/pixel-art/SKILL.md) — Pixel art w/ era palettes (NES, Game Boy, PICO-8).
- [`pretext`](skills/pretext/SKILL.md) — Use when building creative browser demos with @chenglou/pretext — DOM-free text layout for ASCII art, typographic
- [`segment-anything`](skills/segment-anything/SKILL.md) — 'SAM: zero-shot image segmentation via points, boxes, masks.'
- [`sketch`](skills/sketch/SKILL.md) — 'Throwaway HTML mockups: 2-3 design variants to compare.'
- [`songwriting-and-ai-music`](skills/songwriting-and-ai-music/SKILL.md) — Songwriting craft and Suno AI music prompts.
- [`touchdesigner-mcp`](skills/touchdesigner-mcp/SKILL.md) — Control a running TouchDesigner instance via twozero MCP — create operators, set parameters, wire connections,
- [`ui-component-library`](skills/ui-component-library/SKILL.md) — Scaffold a component library (buttons, inputs, cards, modals, nav, badges) from a design system using a target
- [`ui-dashboard`](skills/ui-dashboard/SKILL.md) — Compose a full dashboard layout from a data schema — KPI cards, charts, data tables, filters. AUTO-TRIGGERS when
- [`video-prompting`](skills/video-prompting/SKILL.md) — AI video/image prompt engineering expert. Triggered when users need to write or optimize prompts for AI video or image generation tools. Helps users craft high-quality generation prompts for various m…
- [`web-design-guidelines`](skills/web-design-guidelines/SKILL.md) — UI-Code-Review gegen Vercels Web Interface Guidelines. Nutzen bei "review mein UI", "check accessibility", "audit
- [`audiobook`](skills/audiobook/SKILL.md) — "Audiobook creation assistant. Converts book text into multi-character narrated audio, supporting audiobook production, multi-character voiceover, novel narration, TTS voiceover, and read-aloud scenar…
- [`audiocraft`](skills/audiocraft/SKILL.md) — 'AudioCraft: MusicGen text-to-music, AudioGen text-to-sound.'

## `analyst` — Numbers · Data & ML/Modeling  (14 Skills)
*Daten, ML-Training/Hosting, Modell-Auswahl, Evaluation, RAG-Pipelines.*  
**Trigger:** spreadsheet, model, calculate, chart, data, train, evaluate, benchmark, host llm

- [`axolotl`](skills/axolotl/SKILL.md) — 'Axolotl: YAML LLM fine-tuning (LoRA, DPO, GRPO).'
- [`huggingface-hub`](skills/huggingface-hub/SKILL.md) — 'HuggingFace hf CLI: search/download/upload models, datasets.'
- [`llama-cpp`](skills/llama-cpp/SKILL.md) — llama.cpp local GGUF inference + HF Hub model discovery.
- [`lm-evaluation-harness`](skills/lm-evaluation-harness/SKILL.md) — 'lm-eval-harness: benchmark LLMs (MMLU, GSM8K, etc.).'
- [`mlops-suite`](skills/mlops-suite/SKILL.md) — MLOps tools — model serving (vLLM), local inference (llama.cpp/GGUF), model hub (HuggingFace), experiment tracking (Weights & Biases), audio generation (AudioCraft), image segmentation (SAM), and LLM …
- [`obliteratus`](skills/obliteratus/SKILL.md) — 'OBLITERATUS: abliterate LLM refusals (diff-in-means).'
- [`rag-pipeline-python`](skills/rag-pipeline-python/SKILL.md) — RAG-Pipeline in Python — basierend auf TheMorpheus' Tutorial. Lokale KI mit aktuellem Wissen durch Retrieval Augmented Generation. Ollama + DeepSeek R1 + JSON-Extraktion + Quellenverifizierung.
- [`vllm`](skills/vllm/SKILL.md) — 'vLLM: high-throughput LLM serving, OpenAI API, quantization.'
- [`weights-and-biases`](skills/weights-and-biases/SKILL.md) — 'W&B: log ML experiments, sweeps, model registry, dashboards.'
- [`local-ml-hosting`](skills/local-ml-hosting/SKILL.md) — Local ML model hosting and evaluation — Ollama installation, model selection by VRAM, Hermes integration, GGUF
- [`ollama-local-hosting`](skills/ollama-local-hosting/SKILL.md) — Install, configure, and manage Ollama for local LLM hosting — model selection, VRAM sizing, hardware compatibility,
- [`model-selector`](skills/model-selector/SKILL.md) — Vergleicht verfügbare LLM-Modelle (Nous Portal) und hilft beim Auswählen des richtigen Modells für die jeweilige
- [`dspy`](skills/dspy/SKILL.md) — 'DSPy: declarative LM programs, auto-optimize prompts, RAG.'
- [`llm-evaluation-troubleshooting`](skills/llm-evaluation-troubleshooting/SKILL.md) — "Troubleshooting guide for lm-evaluation-harness and LLM benchmarking setups — Python version compat, dependency chains, local model integration, common errors."

## `writer` — Words · Long-Form Content  (7 Skills)
*Dokumentation, Berichte, PR-Bodies, PDF/PPTX-Deliverables, Langtext.*  
**Trigger:** write a doc, draft a proposal, compose, long copy, documentation, report

- [`epub-export`](skills/epub-export/SKILL.md) — Convert markdown or PDF content to EPUB and deliver to USB/MTP-connected ereaders (Tolino, Kobo, etc.). Covers the full pipeline including PDF extraction, artifact cleaning, CSS optimization, cover ge…
- [`nano-pdf`](skills/nano-pdf/SKILL.md) — Edit PDF text/typos/titles via nano-pdf CLI (NL prompts).
- [`pdf-anthropic`](skills/pdf-anthropic/SKILL.md) — PDF-Verarbeitung (Anthropic offiziell) — Lesen, Extrahieren, Zusammenführen, Splitten, Rotieren, Wasserzeichen, Formulare ausfüllen, Verschlüsseln, OCR. Nutzen bei allen PDF-Operationen.
- [`powerpoint`](skills/powerpoint/SKILL.md) — Create, read, edit .pptx decks, slides, notes, templates.
- [`pr-body-standards`](skills/pr-body-standards/SKILL.md) — PR-Body-Erstellung mit echtem Test-Execution-Vorlauf. 4-Abschnitt-Struktur (Was / Verifiziert / Risk-Register / Deferred), Pre-Existing-vs-Introduced-Trennung, Root-Cause-Tracing auf Code-Pattern-Eben…
- [`system-documentation`](skills/system-documentation/SKILL.md) — Maintain a structured Markdown documentation tree for all system builds, fixes, configurations, and project changes. Gives the user a browsable system overview with context for every change we make.
- [`course-repo-builder`](skills/course-repo-builder/SKILL.md) — "Turn a source video (YouTube tutorial, lecture, course) into a complete, runnable, GitHub-published course-shaped repository. Pipeline: source video → YouTube transcript → N-block course structure → …

## `verifier` — Gate · Adversarial QA & Security  (15 Skills)
*Qualitäts-Gates, Code-/Security-Audits, Verifikation, Härtung, Perf-Tuning.*  
**Trigger:** verify, audit, is this done, check this, security, harden, gate, review

- [`critic-gate`](skills/critic-gate/SKILL.md) — Deterministischer Critic mit hartem Gate — prüft Output-Gate, JSON-Schema, Assertion-Kriterien und vergibt Score. Rückgabe ist strukturiertes JSON für Retry-Entscheidung.
- [`output-validator`](skills/output-validator/SKILL.md) — Pre-Flight Scheck für jeden Output — validiert JSON, Markdown, Python-Syntax und Pflicht-Sektionen BEVOR der Output an den nächsten Schritt weitergegeben wird. Verhindert, dass malformierter Output in…
- [`requesting-code-review`](skills/requesting-code-review/SKILL.md) — 'Pre-commit review: security scan, quality gates, auto-fix.'
- [`security-audit`](skills/security-audit/SKILL.md) — Linux security audits — host security (fwupd HSI, TPM, Secure Boot, kernel taint, power management), system security (ports, services, permissions, firewall), and local AI service hygiene (Ollama inst…
- [`security-code-checker`](skills/security-code-checker/SKILL.md) — Scanner für LLM-generierten Code — erkennt rote Flaggen (Spyware-Patterns, schädliche Funktionalität, unethische Features) BEVOR Code ausgeführt wird. Schützt vor Feature-Creep-Eskalation durch iterat…
- [`simplify-code`](skills/simplify-code/SKILL.md) — Parallel 3-agent cleanup of recent code changes.
- [`test-driven-development`](skills/test-driven-development/SKILL.md) — 'TDD: enforce RED-GREEN-REFACTOR, tests before code.'
- [`verify-before-fix`](skills/verify-before-fix/SKILL.md) — Execute bug fixes from an issue description when locations may be stale, paths may not match repo layout, and bugs may already be partially fixed on the current branch. Verify each listed bug before t…
- [`claude-security-auditor`](skills/claude-security-auditor/SKILL.md) — Security Auditor fuer the user's Zorin OS Workstation. Read-only Reconnaissance Default: Firewall, Ports, Services, Permissions, Credential Exposure, Sudoers, Drift vs Baseline. Migrated aus Claude Co…
- [`host-security-audit`](skills/host-security-audit/SKILL.md) — Audit and harden the host security baseline of a Linux laptop or workstation — fwupd HSI levels, TPM / BootGuard
- [`local-ai-security-hygiene`](skills/local-ai-security-hygiene/SKILL.md) — 'Sichere Installation, Konfiguration und vollständige Entfernung lokaler AI-Services (Ollama, llama.cpp, etc.)
- [`security-attestation-patterns`](skills/security-attestation-patterns/SKILL.md) — Adding audit-guaranteed properties (attestations) to runtime data structures and enforcing them at architectural boundaries — the Kernel-Ebene-4-Attest pattern. Type extension → runtime injection → re…
- [`system-security-audit`](skills/system-security-audit/SKILL.md) — 'Linux-Sicherheitsaudit: offene Ports, Dienste, Berechtigungen, Firewall, Benutzer, Updates, schnelle Fixes.
- [`claude-perf-tuner`](skills/claude-perf-tuner/SKILL.md) — Performance Tuner fuer Zorin OS Workstation. CPU/GPU Power, Gaming Perf (GameMode, NVIDIA PRIME), Thermals, Disk-Space, Memory/Zram, Ollama VRAM. Read-only Diagnose Default. Migrated aus Claude Code a…
- [`1password`](skills/1password/SKILL.md) — Set up and use 1Password CLI (op). Use when installing the CLI, enabling desktop app integration, signing in, and reading/injecting secrets for commands.

## `yuno` — Root · Orchestration & Ops  (29 Skills)
*Orchestrierung, Task-Routing, Multi-Agent-Koordination, Memory, Produktivitäts-/Ops-Automation. Zerlegt Multi-Domain-Tasks und synthetisiert Ergebnisse.*  
**Trigger:** route, orchestrate, plan the work, multi-step, unclear, coordinate, briefing, inbox

- [`yuno-team-routing`](skills/yuno-team-routing/SKILL.md) — Zentrale Routing-Spec für Yuno's Multi-Agent-Team (7 Agents: Yuno + Engineer + Researcher + Designer + Analyst + Writer + Verifier). Load this skill FIRST wenn unklar ist welcher Agent für einen Task …
- [`kanban-orchestrator`](skills/kanban-orchestrator/SKILL.md) — Decomposition playbook + anti-temptation rules for an orchestrator profile routing work through Kanban. The "don't
- [`kanban-worker`](skills/kanban-worker/SKILL.md) — Pitfalls, examples, and edge cases for Hermes Kanban workers. The lifecycle itself is auto-injected into every
- [`multi-agent-master-workflow`](skills/multi-agent-master-workflow/SKILL.md) — 'Generisches Subagent/Master-Controller-Pattern für parallele Analyse-, Audit- und Umsetzungsaufgaben — mappt auf Hermes Queen/Worker/Gate. Use when the user sagt "prüfe systematisch", "analysiere und…
- [`multi-agent-work`](skills/multi-agent-work/SKILL.md) — '/multi-agent-work — Von Research bis Implementierung in einem Durchlauf. 6-Phasen-Workflow: Research → Fixes
- [`nous-multi-lane-routing`](skills/nous-multi-lane-routing/SKILL.md) — Stärken-basiertes Task-Routing mit Provider-Isolation pro Token-Plan. DeepSeek V4 Pro/Flash + StepFun Free via Nous Portal, GLM-5 via Z.ai Token-Plan, MiniMax-M2.7 via Minimax Token-Plan. Kein RAM-Ove…
- [`session-handoff`](skills/session-handoff/SKILL.md) — Erstelle und pflege ein Handoff-Dokument fuer Modell-Wechsel, damit das naechste Modell sofort weiss was los
- [`task-weight-routing`](skills/task-weight-routing/SKILL.md) — Orchestrator-rules for routing coding tasks to cloud agent CLIs — maps task weight (Heavy/Medium/Light) to model selection, budget cap, and max turns based on user-defined policies.
- [`workflow-template`](skills/workflow-template/SKILL.md) — 'Use when the user wants a structured multi-agent plan for a domain task — server hardening, repo cleanup, security/CVE analysis, GreyScript tool dev, or Ollama/LLM setup. Domain-adapter for multi-age…
- [`the-dmz-transfer`](skills/the-dmz-transfer/SKILL.md) — 'Transfer der Multi-Agent Orchestrierungs-Patterns aus the-dmz (TheMorpheus407) auf Hermes/GreyHack. Enthält:
- [`mnemosyne-memory-provider`](skills/mnemosyne-memory-provider/SKILL.md) — Mnemosyne native memory provider for Hermes Agent — embedding engine setup (fastembed), DB schema, vector search,
- [`inline-gate-fallback`](skills/inline-gate-fallback/SKILL.md) — Use when the Telegram-DM channel is not available and user input/decisions are required blockingly. Leitet 2-4 Optionen inline im Chat weiter mit Pattern-7 System-Verifikation vor Implementation.
- [`yuno-user-preferences`](skills/yuno-user-preferences/SKILL.md) — the user's working-style preferences — honest testing over claims, concrete options for decisions, DB-edit safety, whitelist-based cleanup, documentation policy. Load when starting a new session with …
- [`daily-briefing`](skills/daily-briefing/SKILL.md) — Tägliches Briefing zu Beginn jeder Session — System-Status, letzte Aktivität, offene Punkte, Cron-Status.
- [`weekly-insights-synthesis`](skills/weekly-insights-synthesis/SKILL.md) — Periodische Wissensdestillation aus einem Zeitfenster von Doku-Files. Sammelt Dateien eines Domain-Bereichs, extrahiert Highlights, neue Patterns und offene Fragen, und synthetisiert eine strukturiert…
- [`teams-meeting-pipeline`](skills/teams-meeting-pipeline/SKILL.md) — Operate the Teams meeting summary pipeline via Hermes CLI — summarize meetings, inspect pipeline status, replay
- [`telegram-clarification-prompt`](skills/telegram-clarification-prompt/SKILL.md) — Wenn Yuno eine Entscheidung oder Eingabe vom User braucht, wird eine Telegram DM geschickt statt inline zu warten.
- [`agentmail`](skills/agentmail/SKILL.md) — Give the agent its own dedicated email inbox via AgentMail. Send, receive, and manage email autonomously using agent-owned email addresses (e.g. hermes-agent@agentmail.to).
- [`himalaya`](skills/himalaya/SKILL.md) — 'Himalaya CLI: IMAP/SMTP email from terminal.'
- [`google-oauth-setup`](skills/google-oauth-setup/SKILL.md) — Leitfaden zum Einrichten von Google Workspace API (Gmail, Calendar, Drive) mit OAuth2 via Hermes Agent.
- [`google-workspace`](skills/google-workspace/SKILL.md) — Gmail, Calendar, Drive, Docs, Sheets via gws CLI or Python.
- [`messaging-gateway-setup`](skills/messaging-gateway-setup/SKILL.md) — Set up and configure Hermes gateway for messaging platforms — Telegram, Discord, WhatsApp, Signal, and others.
- [`productivity-suite`](skills/productivity-suite/SKILL.md) — Productivity tools — Airtable, Notion, Google Workspace (Gmail, Calendar, Drive), email (Himalaya/IMAP), PDF
- [`notion`](skills/notion/SKILL.md) — 'Notion API + ntn CLI: pages, databases, markdown, Workers.'
- [`linear`](skills/linear/SKILL.md) — 'Linear: manage issues, projects, teams via GraphQL + curl.'
- [`airtable`](skills/airtable/SKILL.md) — Airtable REST API via curl. Records CRUD, filters, upserts.
- [`maps`](skills/maps/SKILL.md) — Geocode, POIs, routes, timezones via OpenStreetMap/OSRM.
- [`canvas`](skills/canvas/SKILL.md) — Canvas LMS integration — fetch enrolled courses and assignments using API token authentication.
- [`model-selector`](skills/model-selector/SKILL.md) — Vergleicht verfügbare LLM-Modelle (Nous Portal) und hilft beim Auswählen des richtigen Modells für die jeweilige
