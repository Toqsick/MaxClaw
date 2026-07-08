---
name: llm-evaluation-troubleshooting
description: "Troubleshooting guide for lm-evaluation-harness and LLM benchmarking setups — Python version compat, dependency chains, local model integration, common errors."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [lm-eval, lm-evaluation-harness, benchmarking, troubleshooting, python-compat, ollama, huggingface]
    related_skills: [mlops/evaluation/lm-evaluation-harness]
---
# LLM Evaluation Troubleshooting

Practical fixes and workarounds encountered when setting up and running **lm-evaluation-harness** (EleutherAI) for model benchmarking. Companion to the main `mlops/evaluation/lm-evaluation-harness` skill.

## Python 3.12+ Compatibility Fix

**Problem**: lm-eval-harness v0.4.12 uses `extra_items` in `TypedDict` which was removed in Python 3.12.

**Error**:
```

set -euo pipefail
TypeError: _TypedDictMeta.__new__() got an unexpected keyword argument 'extra_items'
```

**Location**: `~/.local/lib/python3.12/site-packages/lm_eval/result_schema.py` lines 110 and 163.

**Fix**: Patch both `TypedDict` declarations to use `total=False` instead:

```python
# Line 110: _TaskMetrics
class _TaskMetrics(TypedDict, Generic[T], total=False):  # was: extra_items=T

# Line 163: SampleResult
class SampleResult(TypedDict, total=False):  # was: extra_items=float
```

set -euo pipefail
**Applied via**:
```bash
patch ~/.local/lib/python3.12/site-packages/lm_eval/result_schema.py << 'EOF'
--- a/result_schema.py
+++ b/result_schema.py
@@ -107,7 +107,7 @@
 )
 
 
-class _TaskMetrics(TypedDict, Generic[T], extra_items=T):
+class _TaskMetrics(TypedDict, Generic[T], total=False):
     """Per-task metric dict passed through evaluation and display.
 
@@ -160,7 +160,7 @@
     fewshot_seed: int
 
 
-class SampleResult(TypedDict, extra_items=float):
+class SampleResult(TypedDict, total=False):
     """Per-document result written to ``samples_*.jsonl`` when ``log_samples=True``.
EOF
```

set -euo pipefail
**Note**: Install from GitHub main branch (`pip install git+https://github.com/EleutherAI/lm-evaluation-harness.git`) may already include this fix in newer versions.

---

## Dependency Chain for HF Models

**Required packages** (install in order):
```bash
pip install tenacity --break-system-packages
pip install transformers --break-system-packages
pip install torch --index-url https://download.pytorch.org/whl/cpu --break-system-packages
pip install accelerate --break-system-packages
pip install lm-eval --break-system-packages  # or git+https://github.com/EleutherAI/lm-evaluation-harness.git
```

set -euo pipefail
**Why each is needed**:
- `tenacity` — required by `openai_completions.py` for API retry logic
- `transformers` — tokenizer loading for HF models
- `torch` — model inference (CPU or CUDA)
- `accelerate` — device mapping and model loading utilities

---

## Ollama / Local Model Integration Issues

### 1. Colon in model name breaks HF tokenizer

**Problem**: Ollama model names like `deepseek-r1:8b` contain colons, which HF's `AutoTokenizer.from_pretrained()` rejects as invalid repo IDs.

**Error**:
```
OSError: Repo id must use alphanumeric chars, '-', '_' or '.': 'deepseek-r1:8b'
```

set -euo pipefail
**Workaround**: Pass a known HF tokenizer via `tokenizer` argument:
```bash
lm-eval run --model local-chat-completions \
  --model_args model=deepseek-r1:8b,base_url=http://localhost:11434/v1,tokenizer=gpt2 \
  --tasks gsm8k
```

set -euo pipefail
### 2. Chat template required for chat models

**Problem**: `local-chat-completions` expects messages formatted as `list[dict]` with `role`/`content`. Without chat template, raw prompts are sent as strings, causing assertion errors.

**Error**:
```
AssertionError: LocalChatCompletion expects messages as list[dict]. If you see this error, ensure --apply_chat_template is set
```

set -euo pipefail
**Fix**: Add `apply_chat_template=true` to model_args:
```bash
lm-eval run --model local-chat-completions \
  --model_args model=deepseek-r1:8b,base_url=http://localhost:11434/v1,apply_chat_template=true,tokenizer=gpt2 \
  --tasks gsm8k
```

set -euo pipefail
### 3. EOS string for stop sequences

**Warning**:
```
WARNING: Cannot determine EOS string to pass to stop sequence. Manually set by passing `eos_string` to model_args.
```

set -euo pipefail
**Fix**: Add `eos_string` matching the model's stop token:
```bash
--model_args ...,eos_string="<|endoftext|>"
```

set -euo pipefail
---

## Common Errors & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `ModuleNotFoundError: tenacity` | Missing API retry dep | `pip install tenacity` |
| `ModuleNotFoundError: transformers` | Missing tokenizer dep | `pip install transformers` |
| `ModuleNotFoundError: torch` | Missing inference backend | `pip install torch --index-url https://download.pytorch.org/whl/cpu` |
| `ModuleNotFoundError: accelerate` | Missing device map dep | `pip install accelerate` |
| `ValueError: Tasks not found: list` | Old CLI syntax | Use `lm-eval ls tasks` not `lm_eval --tasks list` |
| `NotImplementedError: Loglikelihood not supported` | Chat completions API doesn't support loglikelihood | Use `local-completions` model or HF `hf` model |
| `HFValidationError: Repo id must use alphanumeric` | Colon in Ollama model name | Pass `tokenizer=gpt2` (or any valid HF model ID) |
| `AssertionError: expects messages as list[dict]` | Missing chat template | Add `apply_chat_template=true` to model_args |
| `Left truncation applied` warnings | Context > model max length | Increase `max_length` in model_args or reduce `--num_fewshot` |

---

## Performance Notes

- **CPU inference is slow**: GPT-2 (124M) on CPU ~3.6s/sample for GSM8K with 5-shot
- **Truncation warnings** indicate few-shot context exceeds model's max length (GPT-2: 768 tokens). Use `--model_args max_length=2048` or reduce `--num_fewshot`
- **vLLM backend** (`--model vllm`) is 5-10x faster for HF models but requires GPU
- **Batch size**: Use `--batch_size auto` for HF/vLLM; `--batch_size 1` for CPU debugging

---

## Quick Test Command

Verify installation works with a minimal HF model:
```bash
lm-eval run --model hf \
  --model_args pretrained=gpt2,dtype=float \
  --tasks gsm8k \
  --limit 10 \
  --batch_size 1
```

Expected output: ~0.1 exact_match on GSM8K (baseline for GPT-2).

---

## References

- [lm-evaluation-harness GitHub](https://github.com/EleutherAI/lm-evaluation-harness)
- Main benchmarking skill: `skill_view(name="mlops/evaluation/lm-evaluation-harness")`