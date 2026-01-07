# Kimi-K2-Thinking GGUF - RunPod Serverless
FROM nvidia/cuda:12.4.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install dependencies
RUN apt-get update && apt-get install -y \
    python3 python3-pip build-essential cmake git curl libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/python3 /usr/bin/python

# Build llama.cpp
WORKDIR /build
RUN git clone https://github.com/ggerganov/llama.cpp && \
    cmake llama.cpp -B llama.cpp/build \
        -DGGML_CUDA=ON -DGGML_CUDA_FA_ALL_QUANTS=ON -DLLAMA_CURL=ON \
        -DCMAKE_BUILD_TYPE=Release -DCMAKE_CUDA_ARCHITECTURES="80;86;89;90" && \
    cmake --build llama.cpp/build --config Release -j$(nproc) && \
    cp llama.cpp/build/bin/llama-server /usr/local/bin/ && \
    rm -rf /build

WORKDIR /app
RUN pip install --no-cache-dir runpod httpx
COPY handler.py .

# Model config - override in RunPod endpoint settings
ENV MODEL_NAME="unsloth/Kimi-K2-Thinking-GGUF"
ENV GGUF_FILE="Kimi-K2-Thinking-UD-Q2_K_XL-00001-of-00006.gguf"
ENV LLAMA_ARGS="--ctx-size 98304 --n-gpu-layers 999 -ot .ffn_.*_exps.=CPU --threads -1 -fa --min-p 0.01 --jinja"

CMD ["python", "-u", "handler.py"]
