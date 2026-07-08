# RTX 5060 Laptop Benchmarks (8GB VRAM)

Real-world performance measurements for Ollama on a Basti RTX 5060 Laptop
with 8GB VRAM. Test date: 2026-06-08.

## Hardware Specs

- **GPU:** NVIDIA GeForce RTX 5060 Laptop (8GB GDDR7)
- **VRAM:** 8 GB (compute 12.0)
- **System RAM:** 32 GB DDR5
- **CPU:** 16 cores
- **PCIe:** Gen 5 (laptop slot, x8 effective)
- **OS:** Ubuntu 24.04 LTS, NVIDIA driver 570+

## Model Benchmarks

| Model                | VRAM   | Speed         | Quality   | Notes                          |
|----------------------|--------|---------------|-----------|--------------------------------|
| deepseek-r1:7b       | ~5 GB  | ~80-100 t/s   | ⭐⭐⭐      | Best VRAM-to-speed ratio       |
| llama3.1:8b          | ~5 GB  | ~70-90 t/s    | ⭐⭐⭐      | Solid general-purpose          |
| qwen2.5:7b           | ~5 GB  | ~80-100 t/s   | ⭐⭐⭐      | Great multilingual             |
| deepseek-r1:8b       | ~5.2 GB| ~30-50 t/s    | ⭐⭐⭐⭐    | Reasoning, slightly slower     |
| qwen3.5:9b           | ~6 GB  | ~50-70 t/s    | ⭐⭐⭐⭐    | Hermes-optimized variant       |
| deepseek-r1:14b      | 8+1GB  | ~4-7 t/s      | ⭐⭐⭐⭐⭐   | CPU-offload, worth it for hard tasks |
| qwen2.5:14b          | 8+1GB  | ~4-7 t/s      | ⭐⭐⭐⭐    | Same as R1:14b in speed        |
| qwen2.5:32b (partial)| 8+11GB | ~15-30 t/s    | ⭐⭐⭐⭐⭐   | Heavy swap, GPT-4 territory   |

## DeepSeek R1:8b max_tokens Test

Same model, varying `max_tokens` with prompt "Antworte in EXAKT einem Wort:
Hallo oder Hi":

| max_tokens | Result                                          | Time  | TPS   | finish_reason |
|------------|-------------------------------------------------|-------|-------|---------------|
| 30         | `content=''`, 30 tokens (all reasoning)         | 1.7s  | 17.6  | `length` ✗    |
| 50         | `content=''`, 50 tokens (all reasoning)         | 2.9s  | 17.2  | `length` ✗    |
| 200        | `content=''`, 200 tokens (all reasoning)        | 11.5s | 17.4  | `length` ✗    |
| 1000       | `content=''`, 1000 tokens (all reasoning)       | 57s   | 17.5  | `length` ✗    |
| 2000       | `content="Hi"`, 354 tokens (330 reasoning)      | 20.2s | 17.5  | `stop` ✓      |

**Conclusion:** R1-Modelle brauchen `max_tokens >= ~2000` für sichtbaren
Content. Reasoning-Trace schluckt sonst das gesamte Budget.

## Context Length Benchmarks

With `OLLAMA_CONTEXT_LENGTH=64000` set in systemd:

| num_ctx | Memory overhead | Speed impact  | Use case              |
|---------|-----------------|---------------|-----------------------|
| 4096    | minimal         | none          | Single-turn chat      |
| 8192    | minimal         | <5%           | Multi-turn chat       |
| 16384   | small           | 5-10%         | Long context tasks    |
| 32768   | small           | 10-15%        | Document analysis     |
| 64000   | ~1 GB VRAM      | 15-25%        | Hermes default        |

## CUDA vs Vulkan

`OLLAMA_VULKAN=false` zwingt CUDA-Nutzung. Ohne diese Einstellung kann Ollama
auf NVIDIA-GPUs den Vulkan-Backend wählen (langsamer).

```bash
journalctl --user -u ollama --since="1 minute ago" --no-pager | grep -i "library="
# library=CUDA compute=12.0 name="NVIDIA GeForce RTX ..."  ← good
# library=Vulkan ...                                         ← slower
```

## Recommendations for 8GB VRAM

1. **Primary model:** `deepseek-r1:8b` (best balance of reasoning + speed)
2. **Speed-pick:** `qwen2.5:7b` or `llama3.1:8b` (raw inference speed)
3. **When you need 14b+ quality:** Accept the 4-7 tok/s penalty
4. **Critic-Gate:** Use `deepseek-r1:8b` (deterministic, JSON-friendly)
5. **Avoid:** Running multiple models simultaneously — `OLLAMA_MAX_LOADED_MODELS=1`