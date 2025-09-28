#!/usr/bin/env bash
set -euo pipefail

# Usage information
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  echo "Usage: $0 [MODEL_VARIANT]"
  echo ""
  echo "MODEL_VARIANT can be:"
  echo "  instruct   - Qwen3-Omni-30B-A3B-Instruct (default)"
  echo "  thinking   - Qwen3-Omni-30B-A3B-Thinking"
  echo "  captioner  - Qwen3-Omni-30B-A3B-Captioner"
  echo ""
  echo "Examples:"
  echo "  $0               # Start instruct variant"
  echo "  $0 thinking      # Start thinking variant"
  echo "  $0 captioner     # Start captioner variant"
  exit 0
fi

# Load shared configuration with argument
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh" "${1:-}"

# -------- Validation --------
echo "=== Docker Container Configuration ==="
echo "  Container name:    $NAME"
echo "  Docker image:      $IMAGE"
echo "  Model variant:     $MODEL_VARIANT"
echo "  Model repo:        $MODEL_REPO"
echo "  Max model length:  $MAX_MODEL_LEN"
echo "  VRAM memory usage: $GPU_MEMORY_UTILIZATION"
echo "  Network:           $NET"
echo "  Network alias:     $ALIAS"
echo "  Port mapping:      ${QWEN_PORT}:8901"
echo "  GPU device:        $GPU_DEVICE"
echo "  HF_HOME:           ${HF_HOME:-<not set>}"
echo "  DATA_DIR:          ${DATA_DIR:-<not set>}"
echo "====================================="

# Check if HF_HOME is set
if [[ -z "${HF_HOME:-}" ]]; then
  echo "Warning: HF_HOME environment variable is not set."
  echo "The container will not have access to local model files."
  read -r -p "Continue anyway? [y/N] " ans
  case "${ans:-N}" in
    y|Y) ;;
    *) echo "Aborted. Please set HF_HOME and try again."; exit 1 ;;
  esac
fi

# Check if Docker image exists
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Error: Docker image '$IMAGE' not found."
  echo "Please build the image first: ./build.sh $MODEL_VARIANT"
  exit 1
fi

# Check if network exists
if ! docker network inspect "$NET" >/dev/null 2>&1; then
  echo "Warning: Docker network '$NET' does not exist."
  read -r -p "Create network '$NET'? [Y/n] " ans
  case "${ans:-Y}" in
    n|N) echo "Aborted."; exit 1 ;;
    *) 
      echo "Creating Docker network '$NET'..."
      if ! docker network create "$NET" 2>/dev/null; then
        # Network might have been created by another process
        if ! docker network inspect "$NET" >/dev/null 2>&1; then
          echo "Error: Failed to create network '$NET'"
          exit 1
        fi
      fi
      ;;
  esac
fi

# -------- Confirmation --------
read -r -p "Start the container? [Y/n] " ans
case "${ans:-Y}" in
  n|N) echo "Aborted."; exit 1 ;;
esac

# -------- Container Management --------
echo "Checking for existing container..."
if docker ps -a --format '{{.Names}}' | grep -q "^${NAME}$"; then
  echo "Removing existing container '$NAME'..."
  docker rm -f "$NAME" >/dev/null
  echo "Container removed."
fi

# -------- Run Container --------
echo "Starting container '$NAME'..."

# Build docker run command
RUN_ARGS=(
  "run" "-d" "--name" "$NAME"
  "--gpus" "$GPU_DEVICE"
  "--network" "$NET" "--network-alias" "$ALIAS"
  "-p" "${QWEN_PORT}:8901"
  "--ipc=host"
  "--ulimit" "memlock=-1" "--ulimit" "stack=67108864"
  "--restart" "unless-stopped"
)

# Add volume mounts
if [[ -n "${HF_HOME:-}" ]]; then
  RUN_ARGS+=("-v" "${HF_HOME}:/models")
fi

# Add data volume mount only if DATA_DIR is set
if [[ -n "${DATA_DIR:-}" ]]; then
  RUN_ARGS+=("-v" "${DATA_DIR}:/data:ro")
fi

RUN_ARGS+=("$IMAGE")

# Add vLLM arguments after the image name (these go to the vLLM command)
# https://docs.vllm.ai/en/v0.5.3/models/engine_args.html#engine-arguments
RUN_ARGS+=(
  "$MODEL_REPO"
  "--dtype" "bfloat16" # ONLY change if you use a different precision finetune/quantization
  "--port" "8901" # do not changeM; if host port binding should change, change the -p argument above
  "--host" "0.0.0.0" # do not change; container must listen on all interfaces
  "--max-model-len" "$MAX_MODEL_LEN" # max sequence length - adjust as needed, adds 2 to VRAM usage
  "--gpu-memory-utilization" "$GPU_MEMORY_UTILIZATION" # factor of VRAM to use (0.90 = 90%) - adjust as needed
  "--enforce-eager" # Operations are executed immediately as they're called (like regular PyTorch) - use this when memory efficiency concern > speed concern
  "-tp" "1" # tensor parallelism (set to number of GPUs if using multi-GPU)
  "--seed" "42" # for reproducibility, if using sampling
  "--rope-scaling" "{\"type\":\"${ROPE_SCALING_TYPE}\",\"factor\":${ROPE_SCALING_FACTOR}}" # adjust for longer context if needed
  "--enable-auto-tool-choice" # enable tool use
  "--tool-call-parser" "hermes" # automatically parse tool calls
  # https://huggingface.co/Qwen/Qwen3-Omni-30B-A3B-Captioner/blob/main/chat_template.json
  # via jq -r '.chat_template' chat_template.json > chat-template.jinja
  "--chat-template" "/opt/vllm/chat-template.jinja2" # original omni chat template extracted from the official repo's chat-template.json
  "--allowed-local-media-path" "/data" # allow media files to be served from the data volume
  "--media-io-kwargs" '{"video":{"num_frames":32,"fps":8}}' # enable video input
)

# Execute docker run
docker "${RUN_ARGS[@]}"

echo "Container '$NAME' started successfully!"
echo "Model variant: $MODEL_VARIANT ($MODEL_REPO)"
echo "API endpoint: http://localhost:$QWEN_PORT/v1/chat/completions"
echo ""
echo "To check logs: docker logs -f $NAME"
echo "To stop:       ./stop.sh $MODEL_VARIANT"