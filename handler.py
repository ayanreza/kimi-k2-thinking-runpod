"""Kimi-K2-Thinking RunPod Serverless Handler"""

import os
import subprocess
import time
import runpod
import httpx

# Config - uses MODEL_NAME for RunPod consistency
MODEL_NAME = os.environ.get("MODEL_NAME", "unsloth/Kimi-K2-Thinking-GGUF")
GGUF_FILE = os.environ.get(
    "GGUF_FILE", "Kimi-K2-Thinking-UD-Q2_K_XL-00001-of-00006.gguf"
)
LLAMA_ARGS = os.environ.get("LLAMA_ARGS", "")
CACHE_DIR = "/runpod-volume/huggingface-cache/hub"
PORT = 8080

server = None


def get_model_path():
    """Resolve cached model path following RunPod conventions."""
    cache_name = MODEL_NAME.replace("/", "--")
    snapshots_dir = os.path.join(CACHE_DIR, f"models--{cache_name}", "snapshots")

    if not os.path.exists(snapshots_dir):
        return None

    snapshots = os.listdir(snapshots_dir)
    if not snapshots:
        return None

    return os.path.join(snapshots_dir, snapshots[0], GGUF_FILE)


def start_server():
    """Start llama-server with cached model."""
    global server

    model_path = get_model_path()
    if not model_path or not os.path.exists(model_path):
        print(f"ERROR: Model not found at {model_path}")
        return False

    print(f"Starting llama-server: {model_path}")

    cmd = ["llama-server", "--model", model_path, "--port", str(PORT)]
    if LLAMA_ARGS:
        cmd.extend(LLAMA_ARGS.split())

    print(f"Command: {' '.join(cmd)}")
    server = subprocess.Popen(cmd)

    # Wait for ready
    for i in range(900):
        try:
            if httpx.get(f"http://127.0.0.1:{PORT}/health", timeout=5).ok:
                print(f"Server ready in {i}s")
                return True
        except:
            pass
        time.sleep(1)

    return False


def handler(event):
    """Handle inference request."""
    inp = event.get("input", {})
    messages = (
        [{"role": "user", "content": inp["prompt"]}]
        if "prompt" in inp
        else inp.get("messages", [])
    )

    resp = httpx.post(
        f"http://127.0.0.1:{PORT}/v1/chat/completions",
        json={
            "messages": messages,
            "temperature": inp.get("temperature", 1.0),
            "max_tokens": inp.get("max_tokens", 4096),
            "min_p": inp.get("min_p", 0.01),
        },
        timeout=600,
    )
    return resp.json()


if __name__ == "__main__":
    if start_server():
        runpod.serverless.start({"handler": handler})
