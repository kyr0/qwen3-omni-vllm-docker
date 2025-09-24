#!/usr/bin/env bash
# Shared configuration for all scripts

# Container configuration
export NAME="qwen3-omni-30b-a3b-instruct"
export IMAGE="qwen3-omni-vllm:local"
export PORT="8901"

# Network configuration
export NET="local-cloud"
export ALIAS="qwen3-omni-30b-a3b-instruct"

# Model configuration
export MODEL_REPO="Qwen/Qwen3-Omni-30B-A3B-Instruct"