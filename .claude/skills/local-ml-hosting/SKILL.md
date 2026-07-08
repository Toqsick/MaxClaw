---
name: local-ml-hosting
description: Local ML model hosting and evaluation — Ollama installation, model selection by VRAM, Hermes integration, GGUF
  context-length pitfalls, and LLM evaluation benchmarks (lm-eval-harness). Covers both Ollama as primary model and as offline
  fallback.
version: 1.0.0
author: Hermes Agent (curator consolidation)
license: MIT
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
    - llm-evaluation
    - lm-eval
    - vram
    - gguf
    related_skills:
    - hermes-admin
    - security-audit
lane: worker-heavy
reasoning_effort: xhigh
---
# Local ML Hosting & Evaluation

Covers: Ollama installation, model selection, Hermes integration, context-length pitfalls, and LLM evaluation benchmarks.

## Ollama Installation & Model Selection

See `references/ollama-local-hosting.md` for full guide.

### Quick Reference
```bash

set -euo pipefail
# Install
curl -fsSL https://ollama.com/install.sh | sh

# Model selection by VRAM
# 4-6 GB:  deepseek-r1:7b, llama3.1:8b, qwen2.5:7b
# 8 GB:   deepseek-r1:8b (fast), deepseek-r1:14b (slow, CPU-offload)
# 12 GB:  qwen2.5:32b (partial), llama3.1:70b (heavy swap)
# 16+ GB: llama3.1:70b, qwen2.5:32b

# Pull model
ollama pull deepseek-r1:8b

# List installed
ollama list
```

### VRAM Budget (Q4_K_M)
| num_ctx | weights | KV cache | total | 8GB GPU |
|---------|---------|----------|-------|---------|
| 8k | 5.5 GB | 1.0 GB | 6.5 GB | ✓ |
| 16k | 5.5 GB | 2.1 GB | 7.6 GB | ✓ tight |
| 24k | 5.5 GB | 3.2 GB | 8.7 GB | ⚠ swap risk |
| 32k | 5.5 GB | 4.2 GB | 9.7 GB | ❌ OOM |

## Hermes Integration

### Config Format (providers dict, recommended)
```yaml
providers:
  ollama-local:
    base_url: http://127.0.0.1:11434/v1
    request_timeout_seconds: 300

fallback_providers:
  - model: deepseek-r1:8b
    provider: custom:ollama-local
```

set -euo pipefail
### Config Format (custom_providers list, legacy)
```yaml
custom_providers:
  - name: ollama-local
    base_url: http://127.0.0.1:11434/v1
    api_key: ollama
    models:
      - deepseek-r1:8b
```

set -euo pipefail
### Provider Name Pitfalls
- `provider: ollama` → Ollama Cloud (NOT local!)
- `provider: ollama-local` → not recognized
- `provider: custom:ollama-local` → CORRECT

### R1 Reasoning Models: max_tokens
R1 models produce reasoning traces before content. `max_tokens < 1000` → empty content.
**Fix:** `max_tokens >= 2000` for R1 calls. In Hermes profile: `max_tokens: 4096`.

### Qwen3.5-Hermes: num_predict Default 128
Ollama default `num_predict=128` silently breaks thinking models.
**Fix:** Recreate model with Modelfile:
```
FROM qwen3.5-9b-hermes
PARAMETER num_ctx 24576
PARAMETER num_batch 4
PARAMETER num_predict 16384
```

set -euo pipefail
Note: `PARAMETER num_batch 4` prevents GGML_ASSERT crash at large contexts.

## Context Window Configuration

**CRITICAL:** Ollama ignores `OLLAMA_CONTEXT_LENGTH` env var AND `~/.ollama/config.yaml` `context_window` when it detects limited VRAM. It silently falls back to a VRAM-based default (often 4096 on 8GB GPUs). The **only reliable fix** is a custom Modelfile.

See `references/ollama-context-window.md` for the full corrected guide.

### Quick Fix (custom Modelfile)
```bash
# ~/.ollama/custom-models/my-model.modelfile
FROM <base-model>
PARAMETER num_ctx 65536
PARAMETER num_batch 4    # REQUIRED to avoid GGML_ASSERT crash
```

set -euo pipefail
```bash
ollama create my-model -f ~/.ollama/custom-models/my-model.modelfile
```

set -euo pipefail
### Per-model context limits (do not exceed these without quality loss)
| Model | Native trained context | Recommended max |
|-------|----------------------|-----------------|
| Gemma 4 E4B | 128K | 131072 |
| Qwen3.5 9B | 32K-128K | 65536-131072 |
| DeepSeek R1 8B | 64K | 65536 |
| Nemotron 3 Super 120B | 8K-32K | 32768 |

**Pitfall:** Setting context_window beyond the model's trained context → hallucinations, forgotten instructions, degraded quality. Stay at or below the trained limit.

**Pitfall:** `OLLAMA_CONTEXT_LENGTH` env var and `~/.ollama/config.yaml` are IGNORED on low-VRAM GPUs. Use custom Modelfile with `PARAMETER num_ctx`.

**Pitfall:** Forgetting `PARAMETER num_batch 4` → `GGML_ASSERT(n_inputs < GGML_SCHED_MAX_SPLIT_INPUTS)` crash at large contexts.

**Pitfall:** Hermes `patch()` blocks writes to `~/.hermes/config.yaml`. Use `hermes config set` or edit manually.

## LLM Evaluation

See `references/llm-evaluation.md` for full guide.

### Quick Reference
```bash
# Install
pip install lm-eval

# Run benchmark
lm_eval --model hf --model_args pretrained=meta-llama/Llama-3.1-8B \
  --tasks mmlu,gsm8k --batch_size auto

# With Ollama
lm_eval --model ollama --model_args model=deepseek-r1:8b \
  --tasks mmlu
```

set -euo pipefail
### OpenAI-compatible custom helper pattern

For custom bots or helper modules that need a provider-neutral LLM call, prefer an OpenAI-compatible `/v1/chat/completions` abstraction instead of wiring directly to one provider SDK.

Typical env shape:

```yaml
LLM_API_BASE_URL: https://api.nousresearch.com/v1   # cloud default
LLM_API_KEY: optional                                # required for cloud, omitted for local Ollama
LOCAL_LLM_MODEL: deepseek-r1:8b
```

set -euo pipefail
For local Ollama:

```yaml
LLM_API_BASE_URL: http://127.0.0.1:11434/v1
LLM_API_KEY: ""
LOCAL_LLM_MODEL: deepseek-r1:8b
```

Important implementation rules:

- Detect local Ollama by endpoint (`http://127.0.0.1:11434/v1` or `http://localhost:11434/v1`).
- Do not require an API key when the endpoint is local Ollama.
- Do not send an `Authorization: Bearer ...` header to local Ollama unless explicitly configured.
- Switch the default model based on backend:
  - cloud/Nous: use the cloud model name, e.g. `qwen/qwen3.6-35b-a3b`
  - local Ollama: use `LOCAL_LLM_MODEL`, e.g. `deepseek-r1:8b`
- Use Ollama `/api/tags` for a lightweight health check.

Pitfall: if the base URL changes to local Ollama but the model name remains a cloud model, Ollama returns `model not found` instead of falling back automatically.

See `references/openai-compatible-endpoint-patterns.md` for a compact integration checklist.

## References

- `references/ollama-local-hosting.md` — Full Ollama guide (install, config, pitfalls, removal)
- `references/ollama-context-window.md` — Corrected context window guide (Modelfile fix, GGML pitfalls, Hermes integration)
- `references/openai-compatible-endpoint-patterns.md` — Provider-neutral helper pattern for cloud LLMs and local Ollama.
- `references/llm-evaluation.md` — LLM evaluation benchmarks (lm-eval-harness, troubleshooting)
