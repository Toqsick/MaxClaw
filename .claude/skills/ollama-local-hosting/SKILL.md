---
name: ollama-local-hosting
description: Install, configure, and manage Ollama for local LLM hosting — model selection, VRAM sizing, hardware compatibility,
  Hermes integration, and performance tuning.
version: 1.0.0
platforms:
- linux
- macos
- windows
metadata:
  hermes:
    tags:
    - ollama
    - local-models
    - self-hosted
    - privacy
    - free
    - hardware
author: Hermes Agent
license: MIT
lane: worker-flash
reasoning_effort: high
---
# Ollama Local Hosting

Install and configure Ollama for fully local, zero-cost, zero-token LLM
inference. For deep dives see `references/`.

## When to Use This Skill

- User wants to run LLMs locally (privacy, cost, offline)
- User has a GPU with 4+ GB VRAM and asks about model recommendations
- User wants to integrate Ollama with Hermes as fallback provider
- User hits `model not found`, slow inference, or CUDA/Vulkan confusion
- User asks "snap vs native", `OLLAMA_NUM_PARALLEL`, `num_predict`,
  context-length issues
- User wants to migrate from Snap to native install (with model preservation)
- User wants to clean up / delete specific local models to free disk space
- `ollama list` shows only some models but disk usage is much higher — orphaned blobs
- User has multiple Ollama installs (system + user) with overlapping models
- User asks "wie viele ollama modelle habe ich" / "zu viele modelle" / "alles bis auf X löschen"

## Quick Start

```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull deepseek-r1:8b      # 5.2 GB Q4 — best balance for 8GB VRAM
ollama run deepseek-r1:8b        # interactive test
```

For user-space install (no sudo, survives upgrades) see
`references/snap-to-native-migration.md`.

## Model Selection (Quick)

Choose by VRAM. Larger models on CPU/RAM are slow — see
`references/hardware-vram-guide.md` for why.

| VRAM     | Recommended Models                              | Speed         | Quality           |
|----------|-------------------------------------------------|---------------|-------------------|
| 4-6 GB   | `deepseek-r1:7b`, `llama3.1:8b`, `qwen2.5:7b`   | 🚀 80-100 t/s | ⭐⭐⭐ (GPT-3.5) |
| 8 GB     | `deepseek-r1:8b`, `qwen3.5:9b`, `qwen2.5:14b`  | 🚀 8B ~30-50, 14B ~4-7 | ⭐⭐⭐⭐ |
| 12 GB    | `qwen2.5:32b` (partial)                         | 🐢 15-30 t/s   | ⭐⭐⭐⭐⭐ (GPT-4) |
| 16+ GB   | `llama3.1:70b`, `qwen2.5:32b` full              | 🐢 8-20 t/s    | ⭐⭐⭐⭐⭐         |

**Sizing rule of thumb (Q4 quantization):** 7-8B ≈ 4-5 GB, 14B ≈ 9 GB,
32B ≈ 19 GB, 70B ≈ 30-40 GB.

**R1 vs Qwen — short version:**

- **R1 (`deepseek-r1:8b`):** Reasoning, structured outputs, JSON, critique.
  Always emits a thinking-trace first → needs `max_tokens >= 2000`.
- **Qwen (`qwen3.5:9b`):** Open generation, tool-use, longer texts.
  Faster, no explicit reasoning trace.

Detailed model recommendations, R1-distill variants, max_tokens test data:
`references/model-recommendations.md`.

## Critical Warnings (TL;DR)

- **Context-Length for Hermes:** Hermes needs ≥64000 tokens context. Ollama
  default is 4096 on <24GB VRAM. Set in systemd user-service:
  ```ini
  Environment="OLLAMA_CONTEXT_LENGTH=64000"
  ```
  Then `systemctl --user daemon-reload && systemctl --user restart ollama`.
- **R1 max_tokens:** R1 reasoning consumes tokens before visible content.
  `max_tokens < ~2000` → empty response, `finish_reason='length'`.
- **`num_predict=128` default breaks thinking models:** Ollama's silent default
  eats the entire budget in the internal `thinking` stream. Fix via Modelfile
  recreation — see `references/qwen-hermes-num-predict-fix.md`.
- **`hermes config set custom_providers '[...]'` saves as YAML string** —
  destroys the list structure. Edit `~/.hermes/config.yaml` directly, or use
  PyYAML script. Details: `references/hermes-config.md`.
- **`model.provider: ollama`** → Ollama Cloud (paid). Use
  **`model.provider: custom:ollama-local`** for local.
- **`ollama ps` empty ≠ Ollama stopped.** Service can run with no model loaded.
  Check `systemctl --user status ollama` + `ss -tlnp | grep 11434`.
- **`ollama list` does NOT show every model on disk.** It only shows models the
  active service knows about. Orphaned manifests/blobs (from `ollama rm`,
  aborted pulls, or another install) sit silently. Always check
  `~/.ollama/models/manifests/` directly before cleanup — see
  `references/model-storage-cleanup.md`.
- **`sudo xargs rm` / `sudo | xargs` from a pipe fails silently.** Sudo needs a
  TTY to prompt for a password; in a pipe it just hangs and fails 3× with
  "3 Fehlversuche bei der Passwort-Eingabe". For destructive sudo loops, write
  a bash script with `set -e` and call `sudo bash /path/to/script.sh` — never
  pipe into `sudo`.
- **Config changes need `/new`** to take effect in active sessions.

## Hermes Integration (Minimal)

`~/.hermes/config.yaml` — minimal `providers:` dict:

```yaml
providers:
  ollama-local:
    base_url: http://127.0.0.1:11434/v1
    request_timeout_seconds: 300

fallback_providers:
  - model: deepseek-r1:8b
    provider: custom:ollama-local
```

Per-session manual switch:
```bash
hermes chat --provider custom:ollama-local --model qwen3.5:9b
```

Full config formats (legacy `custom_providers:`, fallback chains, Critic-Gate,
runtime verification): `references/hermes-config.md`.

## Performance Settings (8GB VRAM)

User systemd service environment (apply in
`~/.config/systemd/user/ollama.service`):

```ini
Environment="OLLAMA_VULKAN=false"        # CUDA on NVIDIA (faster)
Environment="OLLAMA_FLASH_ATTENTION=true"
Environment="OLLAMA_MAX_LOADED_MODELS=1" # critical for 8GB
Environment="OLLAMA_KEEP_ALIVE=10m"
Environment="OLLAMA_NUM_PARALLEL=1"      # save VRAM
```

Verify CUDA actually picked (not Vulkan):
```bash
journalctl --user -u ollama --since="1 minute ago" --no-pager | grep "library="
# Expect: library=CUDA compute=12.0 name="NVIDIA GeForce RTX ..."
```

## Selective Model Cleanup (Free Disk Space)

When the user wants to delete specific models but keep others, **always
dry-run first** — manifests reference shared layer blobs, and a naive
`rm -rf ~/.ollama` kills blobs the kept models still need.

**Storage anatomy** — Ollama stores two layers per model:
- `~/.ollama/models/manifests/<ns>/<model>/<tag>` — JSON with `layers[].digest`
- `~/.ollama/models/blobs/sha256-<digest>` — content-addressed file

Same digest = same file (hardlinked or shared). Deleting a model whose
manifest overlaps with a kept model's manifest removes a shared blob too.
Therefore: classify manifests (KEEP vs DEL), then compute KEEP blobs as the
union of all KEEP-manifest layer digests, then DEL = all blobs − KEEP blobs.

**Multi-install trap.** `ollama list` shows only what the *running* service
sees. `~/.ollama/` (user, `OLLAMA_MODELS=$HOME/.ollama` default) and
`/usr/share/ollama/.ollama` (system install) can coexist with overlapping
model names and zero shared blobs. **Always identify both roots** with
`ps -ef | grep ollama` + `systemctl status ollama` before touching anything.

**Procedure (full recipe in `references/model-storage-cleanup.md`):**

1. Identify KEEP set (friendly names: `library/<model>:<tag>` or
   `<ns>/<model>:<tag>` or `hf.co/<ns>/<model>:<tag>`).
2. Walk all manifests, classify into KEEP/DEL.
3. KEEP blobs = union of layer digests from KEEP manifests.
4. DEL blobs = all blob files − KEEP blobs.
5. Show user exact `rm -rf` commands + expected before/after `du -sh`.
6. Wait for explicit OK, then stop service, run cleanup, restart, verify.

**Path-parsing pitfall (recurring bug).** Manifest paths split differently
depending on namespace:
- `registry.ollama.ai/library/<model>/<tag>` → 4 parts after the root
- `registry.ollama.ai/<ns>/<model>/<tag>` → 5 parts after the root
- `hf.co/<ns>/<model>/<tag>` → 4 parts

A naive `parts[2]/parts[3]:parts[4]` parser misses everything in `library/`.
Use explicit branch-by-prefix parsing. Reference implementation lives in
`references/model-storage-cleanup.md#dry-run-script`.

## Troubleshooting (Quick)

- **Slow inference:** Model is swapping to RAM. Use a smaller model that fits
  VRAM. See `references/hardware-vram-guide.md`.
- **"model not found":** Run `ollama pull <model>` first.
- **Ollama not accessible:** `systemctl --user status ollama`,
  `ss -tlnp | grep 11434`.
- **Empty response with R1 model:** `max_tokens >= 2000`. See
  `references/model-recommendations.md#r1-reasoning-models-max_tokens-fallstrick`.
- **Curl hangs with 0% CPU:** Single-slot queue (a previous long gen owns the
  slot). Check `journalctl --user -u ollama | grep "slot print_timing"`. Wait
  it out or `--max-time 300`. **Don't `kill` blindly** — you may cancel a
  real job. See `references/qwen-hermes-num-predict-fix.md#single-slot-queue-hangs`.
- **Port 11434 already in use:** Often an old Snap or global install.
  `sudo lsof -i :11434`. See `references/snap-to-native-migration.md`.

## Complete Uninstallation

```bash
systemctl --user stop ollama && systemctl --user disable ollama
rm -f ~/.config/systemd/user/ollama.service
rm -rf ~/.ollama ~/.local/bin/ollama ~/.local/lib/ollama
sudo rm -f /usr/local/bin/ollama /etc/systemd/system/ollama.service
sudo snap remove --purge ollama 2>/dev/null
systemctl --user daemon-reload
```

Verify: `which ollama` (empty), `ss -tlnp | grep 11434` (empty),
`systemctl --user status ollama` ("could not be found").

## References

- **`references/model-recommendations.md`** — Detailed model picks, R1 distill
  variants, R1 max_tokens test data, model storage paths, background download
  pattern for models >4GB.
- **`references/hardware-vram-guide.md`** — Why VRAM >> DDR5 for LLMs,
  CPU-offload performance math, quantization trade-offs, MoE models.
- **`references/rtx-5060-benchmarks.md`** — Concrete RTX 5060 Laptop (8GB)
  benchmarks, CUDA vs Vulkan, context-length overhead.
- **`references/hermes-config.md`** — Both config formats, fallback chains,
  Critic-Gate setup, runtime verification, context-length, multi-install
  conflicts.
- **`references/snap-to-native-migration.md`** — Full Snap → native migration
  with model preservation, CUDA-optimized user-systemd service recipe.
- **`references/qwen-hermes-num-predict-fix.md`** — num_predict=128 silent
  default fix, Modelfile recreation recipe, num_predict sizing table, single-
  slot queue hang diagnosis.
- **`references/offline-fallback-strategy.md`** — Strategies for Ollama as
  offline fallback (manual switch, pre-flight script, Hermes fallback chain).
- **`references/model-storage-cleanup.md`** — Storage anatomy, multi-install
  detection, dry-run script that classifies manifests/blobs by KEEP set,
  path-parsing pitfalls, safe `rm` recipe (bash script, not `sudo xargs`).
  Load when user wants to delete specific models or asks "zu viele modelle".

> **Note:** PodTalk/TheCommunity P2P chat integration (WebRTC, local AI
> provider setup) ist nicht Teil dieses Skills — wurde beim Slim-Down
> entfernt, da keine Reference-Datei existierte. Inhalt kann bei Bedarf
> nachgereicht werden, ist aber nicht kritisch für den Hauptworkflow.