# Kimi-K2-Thinking on RunPod Serverless

Deploy [Kimi-K2-Thinking-GGUF](https://huggingface.co/unsloth/Kimi-K2-Thinking-GGUF) on RunPod.

## Hardware Requirements

| Quant | Disk | RAM+VRAM Needed | Speed |
|-------|------|-----------------|-------|
| **UD-TQ1_0** (1-bit) | 247GB | 247GB | 5+ tok/s |
| **UD-Q2_K_XL** (2-bit) | 360GB | 360GB | 5+ tok/s |

**With MoE CPU offloading (`-ot` flag):**
- VRAM drops to **~8GB** (fits on any modern GPU!)
- Rest goes to RAM
- Works with less RAM via disk mmap (slower: <1 tok/s)

## Files

```
kimi-k2/
├── Dockerfile     # llama.cpp with CUDA + MoE offloading
├── handler.py     # RunPod handler
└── requirements.txt
```

## Key Features

- ✅ **MoE CPU Offloading** - Only needs ~8GB VRAM
- ✅ **Moonshot AI settings** - temp=1.0, min_p=0.01, ctx=98304
- ✅ **RunPod model caching** - Free, no storage costs

## Deploy

### 1. Build & Push

```bash
docker build -t yourusername/kimi-k2-runpod:latest .
docker push yourusername/kimi-k2-runpod:latest
```

### 2. Create RunPod Endpoint

1. [RunPod Serverless](https://console.runpod.io/serverless) → **New Endpoint**
2. **Docker image**: `yourusername/kimi-k2-runpod:latest`
3. **Model**: `unsloth/Kimi-K2-Thinking-GGUF`
4. **GPU**: Any GPU with 24GB+ VRAM (RTX 4090, A100, etc.)
5. **Important**: Choose instance with **high RAM** (256GB+ recommended)

### 3. Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MODEL_FILE` | `Kimi-K2-Thinking-UD-Q2_K_XL.gguf` | Which quant |
| `CONTEXT_LENGTH` | `98304` | Context window |
| `GPU_LAYERS` | `99` | Layers on GPU |
| `MOE_OFFLOAD` | `.ffn_.*_exps.=CPU` | MoE offload pattern |

**Offload options (less VRAM = more RAM needed):**
```
.ffn_.*_exps.=CPU           # Minimum VRAM (~8GB)
.ffn_(up|down)_exps.=CPU    # Medium VRAM
.ffn_(up)_exps.=CPU         # More VRAM
```

### 4. Test

```python
import openai

client = openai.OpenAI(
    base_url="https://api.runpod.ai/v2/YOUR_ENDPOINT_ID/openai/v1",
    api_key="YOUR_RUNPOD_API_KEY"
)

response = client.chat.completions.create(
    model="kimi-k2",
    messages=[{"role": "user", "content": "Which is bigger: 9.11 or 9.9?"}],
    temperature=1.0
)
print(response.choices[0].message.content)
```

## Cost Estimate

With MoE offloading, you can use **cheaper GPUs**:

| GPU | VRAM | Hourly | Works? |
|-----|------|--------|--------|
| RTX 4090 | 24GB | ~$0.50 | ✅ (need 256GB+ RAM) |
| A100 40GB | 40GB | ~$1.50 | ✅ |
| A100 80GB | 80GB | ~$2.00 | ✅ |
| H100 80GB | 80GB | ~$4.00 | ✅ |

**Note**: Speed depends on RAM. With <360GB RAM+VRAM, expect slower inference (<1 tok/s via disk mmap).

## References

- [Unsloth Kimi-K2 Guide](https://unsloth.ai/docs/models/kimi-k2-thinking-how-to-run-locally)
- [Model on HuggingFace](https://huggingface.co/unsloth/Kimi-K2-Thinking-GGUF)
- [RunPod Model Caching](https://docs.runpod.io/serverless/endpoints/model-caching)
