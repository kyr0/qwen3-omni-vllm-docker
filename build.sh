#!/usr/bin/env bash
set -euo pipefail

# Load shared configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

echo "=== Building Docker Image ==="
echo "  Image name: $IMAGE"
echo "=============================="

# Build the image
echo "Building Docker image..."
docker build -t "$IMAGE" .

echo "Image '$IMAGE' built successfully!"
echo ""
echo "Next steps:"
echo "  1. Download model: ./download-model.sh"
echo "  2. Start container: ./start.sh"