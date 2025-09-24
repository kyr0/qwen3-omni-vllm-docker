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
  echo "  $0               # Stop instruct variant"
  echo "  $0 thinking      # Stop thinking variant"
  echo "  $0 captioner     # Stop captioner variant"
  exit 0
fi

# Load shared configuration with argument
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh" "${1:-}"

echo "=== Stopping Docker Container ==="
echo "  Container name: $NAME"
echo "  Model variant:  $MODEL_VARIANT"
echo "================================="

# Check if container exists
if ! docker ps -a --format '{{.Names}}' | grep -q "^${NAME}$"; then
  echo "Container '$NAME' does not exist."
  exit 0
fi

# Check container status
CONTAINER_STATUS=$(docker inspect -f '{{.State.Status}}' "$NAME" 2>/dev/null || echo "not found")

case "$CONTAINER_STATUS" in
  "running")
    echo "Container '$NAME' is currently running."
    ;;
  "exited")
    echo "Container '$NAME' is stopped but still exists."
    ;;
  "paused")
    echo "Container '$NAME' is paused."
    ;;
  *)
    echo "Container '$NAME' status: $CONTAINER_STATUS"
    ;;
esac

# Confirmation
read -r -p "Stop and remove container '$NAME'? [Y/n] " ans
case "${ans:-Y}" in
  n|N) 
    echo "Aborted."
    exit 0
    ;;
esac

# Stop and remove container
echo "Stopping and removing container '$NAME'..."
if docker rm -f "$NAME" >/dev/null 2>&1; then
  echo "Container '$NAME' stopped and removed successfully!"
else
  echo "Failed to stop/remove container '$NAME'."
  exit 1
fi