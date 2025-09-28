#!/usr/bin/env bash
# Shared configuration for all scripts

# Model variant - from argument, environment variable, or default
if [[ -n "${1:-}" ]]; then
  export MODEL_VARIANT="$1"
elif [[ -n "${MODEL_VARIANT:-}" ]]; then
  export MODEL_VARIANT="$MODEL_VARIANT"
else
  export MODEL_VARIANT="instruct"
fi

# Validate model variant
case "${MODEL_VARIANT,,}" in
  instruct)
    MODEL_SUFFIX="Instruct"
    ;;
  thinking)
    MODEL_SUFFIX="Thinking"
    ;;
  captioner)
    MODEL_SUFFIX="Captioner"
    ;;
  *)
    echo "Error: Invalid MODEL_VARIANT '$MODEL_VARIANT'. Must be one of: instruct, thinking, captioner"
    exit 1
    ;;
esac

# Normalize MODEL_VARIANT to lowercase for consistency
export MODEL_VARIANT="${MODEL_VARIANT,,}"

# Container configuration (includes model variant in name)
export NAME="qwen3-omni-30b-a3b-${MODEL_VARIANT}"
export IMAGE="qwen3-omni-vllm:${MODEL_VARIANT}"
export QWEN_PORT="${QWEN_PORT:-8901}"  # Allow override via environment

# Network configuration
export NET="local-cloud"
export ALIAS="qwen3-omni-30b-a3b-${MODEL_VARIANT}"

# Model configuration
export MODEL_REPO="Qwen/Qwen3-Omni-30B-A3B-${MODEL_SUFFIX}"
export MODEL_SUFFIX
export MAX_MODEL_LEN=65536  # Max native model context length
export GPU_MEMORY_UTILIZATION=0.8  # Fraction of GPU memory to utilize (H200 optimized)
export GPU_DEVICE="all" # Use all available GPUs

# Data volume configuration for multimodal use
export DATA_DIR="${DATA_DIR:-/var/lib/docker/projects/sample_data}"  # Host directory to mount as /data:ro in container

# RoPE scaling configuration
export ROPE_SCALING_TYPE="linear"  # or "dynamic" or "ntk"
export ROPE_SCALING_FACTOR=2.0     # 2x context extension