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
echo "  Network:           $NET"
echo "  Network alias:     $ALIAS"
echo "  Port mapping:      ${PORT}:8901"
echo "  GPU device:        0"
echo "  HF_HOME:           ${HF_HOME:-<not set>}"
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
      docker network create "$NET"
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
  "--gpus" "device=0"
  "--network" "$NET" "--network-alias" "$ALIAS"
  "-p" "${PORT}:8901"
  "--ipc=host"
  "--ulimit" "memlock=-1" "--ulimit" "stack=67108864"
  "-e" "MODEL_REPO=$MODEL_REPO"
)

# Add volume mount only if HF_HOME is set
if [[ -n "${HF_HOME:-}" ]]; then
  RUN_ARGS+=("-v" "${HF_HOME}:/models")
fi

RUN_ARGS+=("$IMAGE")

# Execute docker run
docker "${RUN_ARGS[@]}"

echo "Container '$NAME' started successfully!"
echo "Model variant: $MODEL_VARIANT ($MODEL_REPO)"
echo "API endpoint: http://localhost:${PORT}"
echo ""
echo "To check logs: docker logs -f $NAME"
echo "To stop:       ./stop.sh $MODEL_VARIANT"