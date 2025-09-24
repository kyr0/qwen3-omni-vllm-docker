#!/usr/bin/env bash
set -euo pipefail

# Usage information
usage() {
  echo "Usage: $0 [MODEL_VARIANT] [OPTIONS]"
  echo ""
  echo "MODEL_VARIANT:"
  echo "  instruct   - Qwen3-Omni-30B-A3B-Instruct (default)"
  echo "  thinking   - Qwen3-Omni-30B-A3B-Thinking"
  echo "  captioner  - Qwen3-Omni-30B-A3B-Captioner"
  echo ""
  echo "OPTIONS:"
  echo "  -f, --follow    Follow log output (like tail -f)"
  echo "  -n, --lines N   Show last N lines (default: 100)"
  echo "  -t, --tail      Show only new log entries"
  echo "  -s, --since     Show logs since timestamp (e.g., 2m, 1h)"
  echo ""
  echo "Examples:"
  echo "  $0                    # Show last 100 lines for instruct variant"
  echo "  $0 thinking -f        # Follow thinking variant logs"
  echo "  $0 captioner -n 50    # Show last 50 lines for captioner"
  echo "  $0 instruct --since 5m # Show logs from last 5 minutes"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

# Load shared configuration with argument
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh" "${1:-}"

# Parse additional arguments
DOCKER_ARGS=()
FOLLOW=false
LINES=100

# Shift past model variant argument if provided
if [[ -n "${1:-}" && "${1}" != -* ]]; then
  shift
fi

# Parse remaining arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--follow)
      FOLLOW=true
      DOCKER_ARGS+=("--follow")
      shift
      ;;
    -n|--lines)
      if [[ -n "${2:-}" && "${2}" =~ ^[0-9]+$ ]]; then
        LINES="$2"
        shift 2
      else
        echo "Error: --lines requires a number"
        exit 1
      fi
      ;;
    -t|--tail)
      DOCKER_ARGS+=("--tail" "0")
      LINES=""
      shift
      ;;
    -s|--since)
      if [[ -n "${2:-}" ]]; then
        DOCKER_ARGS+=("--since" "$2")
        shift 2
      else
        echo "Error: --since requires a timestamp"
        exit 1
      fi
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# Add lines argument if not using --tail
if [[ -n "$LINES" ]]; then
  DOCKER_ARGS+=("--tail" "$LINES")
fi

# Colors for output
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Container Logs ===${NC}"
echo "Container: $NAME"
echo "Model variant: $MODEL_VARIANT"
echo "Model repo: $MODEL_REPO"

# Check if container exists
if ! docker ps -a --format '{{.Names}}' | grep -q "^${NAME}$"; then
  echo -e "${RED}Error: Container '$NAME' does not exist.${NC}"
  echo "Create it with: ./start.sh $MODEL_VARIANT"
  exit 1
fi

# Show container status
CONTAINER_STATUS=$(docker inspect -f '{{.State.Status}}' "$NAME" 2>/dev/null || echo "unknown")
echo "Status: $CONTAINER_STATUS"

if [[ "$FOLLOW" == true ]]; then
  echo "Following logs (press Ctrl+C to stop)..."
else
  echo "Showing logs..."
fi

echo "----------------------------------------"

# Execute docker logs with collected arguments
exec docker logs "${DOCKER_ARGS[@]}" "$NAME"