FROM aimehub/pytorch-2.8.0-aime-cuda12.8.1

# Build argument for model variant
ARG MODEL_VARIANT=instruct
ARG MODEL_REPO=Qwen/Qwen3-Omni-30B-A3B-Instruct

# vLLM for Qwen3 Omni
RUN git clone -b qwen3_omni https://github.com/wangxiongts/vllm.git /opt/vllm
WORKDIR /opt/vllm
RUN pip install --break-system-packages -r requirements/build.txt && \
    pip install --break-system-packages -r requirements/cuda.txt && \
    export VLLM_PRECOMPILED_WHEEL_LOCATION="https://wheels.vllm.ai/a5dd03c1ebc5e4f56f3c9d3dc0436e9c582c978f/vllm-0.9.2-cp38-abi3-manylinux1_x86_64.whl" && \
    VLLM_USE_PRECOMPILED=1 pip install --break-system-packages -e . -v --no-build-isolation || pip install --break-system-packages -e . -v

# Extras
RUN pip install --break-system-packages "git+https://github.com/huggingface/transformers" \
    accelerate qwen-omni-utils -U \
    "flash-attn>=2.6.0" --no-build-isolation

# Set Hugging Face caches to /models (the mounted volume)
ENV HF_HOME=/models \
    TRANSFORMERS_CACHE=/models \
    HUGGINGFACE_HUB_CACHE=/models

# Store model info as environment variables
ENV MODEL_VARIANT=${MODEL_VARIANT} \
    MODEL_REPO=${MODEL_REPO}

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8901/health || exit 1

EXPOSE 8901

# Create entrypoint script to use dynamic model
RUN echo '#!/bin/bash\n\
MODEL_REPO=${MODEL_REPO:-"Qwen/Qwen3-Omni-30B-A3B-Instruct"}\n\
exec vllm serve "$MODEL_REPO" \\\n\
     --port 8901 \\\n\
     --host 0.0.0.0 \\\n\
     --dtype bfloat16 \\\n\
     --max-model-len 32768 \\\n\
     --allowed-local-media-path / \\\n\
     -tp 1' > /entrypoint.sh && chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]