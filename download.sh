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
  echo "  $0               # Download instruct variant"
  echo "  $0 thinking      # Download thinking variant"
  echo "  $0 captioner     # Download captioner variant"
  exit 0
fi

# Load shared configuration with argument
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh" "${1:-}"

echo "=== Downloading Model ==="
echo "  Model variant: $MODEL_VARIANT"
echo "  Model repo:    $MODEL_REPO"
echo "========================="

# Check if HF_HOME is set
if [[ -z "${HF_HOME:-}" ]]; then
  echo "Warning: HF_HOME not set. Using default HuggingFace cache location."
fi

# Download the model
echo "Downloading model files..."
huggingface-cli download "$MODEL_REPO" --local-dir-use-symlinks False

echo "Model '$MODEL_REPO' downloaded successfully!"