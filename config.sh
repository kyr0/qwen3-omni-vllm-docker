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

# Container configuration (includes model variant in name)
export NAME="qwen3-omni-30b-a3b-${MODEL_VARIANT,,}"
export IMAGE="qwen3-omni-vllm:${MODEL_VARIANT,,}"
export PORT="8901"

# Network configuration
export NET="local-cloud"
export ALIAS="qwen3-omni-30b-a3b-${MODEL_VARIANT,,}"

# Model configuration
export MODEL_REPO="Qwen/Qwen3-Omni-30B-A3B-${MODEL_SUFFIX}"
export MODEL_SUFFIX