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
  echo "  $0               # Build instruct variant"
  echo "  $0 thinking      # Build thinking variant"
  echo "  $0 captioner     # Build captioner variant"
  exit 0
fi

# Load shared configuration with argument
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh" "${1:-}"

echo "=== Building Docker Image ==="
echo "  Image name:     $IMAGE"
echo "  Model variant:  $MODEL_VARIANT"
echo "  Model repo:     $MODEL_REPO"
echo "=============================="

# Build the image with build arguments
echo "Building Docker image..."
docker build --progress=plain \
  -t "$IMAGE" .

echo "Image '$IMAGE' built successfully!"
echo ""
echo "Next steps:"
echo "  1. Download model: ./download.sh $MODEL_VARIANT"
echo "  2. Start container: ./start.sh $MODEL_VARIANT"