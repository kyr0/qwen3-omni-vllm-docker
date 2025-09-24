FROM aimehub/pytorch-2.8.0-aime-cuda12.8.1

RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential python3-dev && rm -rf /var/lib/apt/lists/*

# vLLM for Qwen3 Omni
RUN git clone -b qwen3_omni https://github.com/wangxiongts/vllm.git /opt/vllm
WORKDIR /opt/vllm
RUN pip install -r requirements/build.txt && \
    pip install -r requirements/cuda.txt && \
    export VLLM_PRECOMPILED_WHEEL_LOCATION="https://wheels.vllm.ai/a5dd03c1ebc5e4f56f3c9d3dc0436e9c582c978f/vllm-0.9.2-cp38-abi3-manylinux1_x86_64.whl" && \
    VLLM_USE_PRECOMPILED=1 pip install -e . -v --no-build-isolation || pip install -e . -v

# Extras
RUN pip install "git+https://github.com/huggingface/transformers" \
    accelerate qwen-omni-utils -U \
    "flash-attn>=2.6.0" --no-build-isolation

# Set Hugging Face caches to /models (the mounted volume)
ENV HF_HOME=/models \
    TRANSFORMERS_CACHE=/models \
    HUGGINGFACE_HUB_CACHE=/models

EXPOSE 8901

# Default CMD is your raw vLLM serve
CMD ["vllm", "serve", "Qwen/Qwen3-Omni-30B-A3B-Instruct",
     "--port", "8901",
     "--host", "0.0.0.0",
     "--dtype", "bfloat16",
     "--max-model-len", "32768",
     "--allowed-local-media-path", "/",
     "-tp", "1"]
