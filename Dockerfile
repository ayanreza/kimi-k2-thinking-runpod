# Use official llama.cpp server image with CUDA
FROM ghcr.io/ggml-org/llama.cpp:server-cuda

# Install Python for RunPod handler
RUN apt-get update && apt-get install -y python3 python3-pip && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN pip install --no-cache-dir runpod httpx
COPY handler.py .

ENV MODEL_NAME="unsloth/Kimi-K2-Thinking-GGUF"
ENV GGUF_FILE="Kimi-K2-Thinking-UD-Q2_K_XL-00001-of-00006.gguf"
ENV LLAMA_ARGS="--ctx-size 98304 --n-gpu-layers 999 -ot .ffn_.*_exps.=CPU --threads -1 -fa --min-p 0.01 --jinja"

CMD ["python", "-u", "handler.py"]
