#!/usr/bin/env bash
set -euo pipefail

# Load shared configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh" "${1:-}"

# Configuration
API_BASE="http://localhost:${QWEN_PORT}"
TIMEOUT=30

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage information
usage() {
  echo "Usage: $0 [MODEL_VARIANT] [TEST_TYPE]"
  echo ""
  echo "MODEL_VARIANT:"
  echo "  instruct   - Qwen3-Omni-30B-A3B-Instruct (default)"
  echo "  thinking   - Qwen3-Omni-30B-A3B-Thinking"
  echo "  captioner  - Qwen3-Omni-30B-A3B-Captioner"
  echo ""
  echo "TEST_TYPE:"
  echo "  health     - Health check only"
  echo "  text       - Text-only chat completion"
  echo "  audio      - Audio input test"
  echo "  image      - Image input test"
  echo "  multimodal - Combined audio + text test"
  echo "  all        - Run all tests (default)"
  echo ""
  echo "Examples:"
  echo "  $0                    # Test instruct variant with all tests"
  echo "  $0 thinking           # Test thinking variant with all tests"
  echo "  $0 captioner health   # Health check for captioner variant"
  echo "  $0 instruct audio     # Audio test for instruct variant"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

# Parse arguments
TEST_TYPE="${2:-all}"

# Helper functions
print_header() {
  echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
  echo -e "${RED}❌ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if container is running
check_container() {
  if ! docker ps --format '{{.Names}}' | grep -q "^${NAME}$"; then
    print_error "Container '$NAME' is not running."
    echo "Start it with: ./start.sh $MODEL_VARIANT"
    exit 1
  fi
}

# Health check
test_health() {
  print_header "Health Check"
  
  if curl -sf --connect-timeout "$TIMEOUT" "$API_BASE/health" >/dev/null 2>&1; then
    print_success "API health check passed"
    return 0
  else
    print_error "API health check failed"
    print_info "Container may still be starting up. Check logs: docker logs -f $NAME"
    return 1
  fi
}

# Test basic text completion
test_text() {
  print_header "Text Completion Test"
  
  local response
  response=$(curl -sf --connect-timeout "$TIMEOUT" \
    -H "Content-Type: application/json" \
    -d '{
      "model": "'"$MODEL_REPO"'",
      "messages": [
        {"role": "user", "content": "Hello! Please respond with a short greeting."}
      ],
      "max_tokens": 500,
      "temperature": 0.1
    }' \
    "$API_BASE/v1/chat/completions" 2>/dev/null)
  
  if [[ -n "$response" ]] && echo "$response" | jq -e '.choices[0].message.content' >/dev/null 2>&1; then
    print_success "Text completion test passed"
    local content
    content=$(echo "$response" | jq -r '.choices[0].message.content')
    print_info "Response: $content"
    return 0
  else
    print_error "Text completion test failed"
    echo "Response: $response"
    return 1
  fi
}

# Test audio input
test_audio() {
  print_header "Audio Input Test"
  
  local response
  response=$(curl -sf --connect-timeout "$TIMEOUT" \
    -H "Content-Type: application/json" \
    -d '{
      "model": "'"$MODEL_REPO"'",
      "messages": [
        {"role": "user", "content": [
          {"type": "audio_url", "audio_url": {"url": "https://qianwen-res.oss-cn-beijing.aliyuncs.com/Qwen3-Omni/cookbook/caption2.mp3"}}
        ]}
      ],
      "max_tokens": 500,
      "temperature": 0.1
    }' \
    "$API_BASE/v1/chat/completions" 2>/dev/null)
  
  if [[ -n "$response" ]] && echo "$response" | jq -e '.choices[0].message.content' >/dev/null 2>&1; then
    print_success "Audio input test passed"
    local content
    content=$(echo "$response" | jq -r '.choices[0].message.content')
    print_info "Audio response: $content"
    return 0
  else
    print_error "Audio input test failed"
    echo "Response: $response"
    return 1
  fi
}

# Test image input
test_image() {
  print_header "Image Input Test"
  
  local response
  response=$(curl -sf --connect-timeout "$TIMEOUT" \
    -H "Content-Type: application/json" \
    -d '{
      "model": "'"$MODEL_REPO"'",
      "messages": [
        {"role": "user", "content": [
          {"type": "image_url", "image_url": {"url": "https://raw.githubusercontent.com/kyr0/defuss/refs/heads/main/assets/defuss_comic.png"}},
          {"type": "text", "text": "What do you see in this image?"}
        ]}
      ],
      "max_tokens": 500,
      "temperature": 0.1
    }' \
    "$API_BASE/v1/chat/completions" 2>/dev/null)
  
  if [[ -n "$response" ]] && echo "$response" | jq -e '.choices[0].message.content' >/dev/null 2>&1; then
    print_success "Image input test passed"
    local content
    content=$(echo "$response" | jq -r '.choices[0].message.content')
    print_info "Image response: $content"
    return 0
  else
    print_error "Image input test failed"
    echo "Response: $response"
    return 1
  fi
}

# Test multimodal input
test_multimodal() {
  print_header "Multimodal Input Test"
  
  local response
  response=$(curl -sf --connect-timeout "$TIMEOUT" \
    -H "Content-Type: application/json" \
    -d '{
      "model": "'"$MODEL_REPO"'",
      "messages": [
        {"role": "user", "content": [
          {"type": "audio_url", "audio_url": {"url": "https://qianwen-res.oss-cn-beijing.aliyuncs.com/Qwen3-Omni/cookbook/asr_en.wav"}},
          {"type": "image_url", "image_url": {"url": "https://raw.githubusercontent.com/kyr0/defuss/refs/heads/main/assets/defuss_comic.png"}},
          {"type": "text", "text": "Please describe what you hear and see:"}
        ]}
      ],
      "max_tokens": 500,
      "temperature": 0.1
    }' \
    "$API_BASE/v1/chat/completions" 2>/dev/null)
  
  if [[ -n "$response" ]] && echo "$response" | jq -e '.choices[0].message.content' >/dev/null 2>&1; then
    print_success "Multimodal input test passed"
    local content
    content=$(echo "$response" | jq -r '.choices[0].message.content')
    print_info "Multimodal response: $content"
    return 0
  else
    print_error "Multimodal input test failed"
    echo "Response: $response"
    return 1
  fi
}

# Test model info
test_model_info() {
  print_header "Model Information"
  
  local response
  response=$(curl -sf --connect-timeout "$TIMEOUT" "$API_BASE/v1/models" 2>/dev/null)
  
  if [[ -n "$response" ]] && echo "$response" | jq -e '.data[0].id' >/dev/null 2>&1; then
    print_success "Model info retrieved"
    local model_id
    model_id=$(echo "$response" | jq -r '.data[0].id')
    print_info "Active model: $model_id"
    return 0
  else
    print_error "Failed to retrieve model info"
    echo "Response: $response"
    return 1
  fi
}

# Main test runner
run_tests() {
  local failed=0
  
  print_header "Testing API for $MODEL_VARIANT variant"
  print_info "Container: $NAME"
  print_info "API Base: $API_BASE"
  print_info "Model: $MODEL_REPO"
  
  # Check if jq is available
  if ! command -v jq >/dev/null 2>&1; then
    print_error "jq is required for JSON parsing. Install with: brew install jq"
    exit 1
  fi
  
  # Check container status
  check_container
  
  # Always run health check first
  if ! test_health; then
    print_error "Health check failed. Skipping other tests."
    exit 1
  fi
  
  # Get model info
  test_model_info || ((failed++))
  
  # Run specific test or all tests
  case "$TEST_TYPE" in
    "health")
      # Health check already done
      ;;
    "text")
      test_text || ((failed++))
      ;;
    "audio")
      test_audio || ((failed++))
      ;;
    "image")
      test_image || ((failed++))
      ;;
    "multimodal")
      test_multimodal || ((failed++))
      ;;
    "all")
      test_text || ((failed++))
      test_audio || ((failed++))
      test_image || ((failed++))
      test_multimodal || ((failed++))
      ;;
    *)
      print_error "Unknown test type: $TEST_TYPE"
      usage
      exit 1
      ;;
  esac
  
  # Summary
  print_header "Test Summary"
  if [[ $failed -eq 0 ]]; then
    print_success "All tests passed! 🎉"
  else
    print_error "$failed test(s) failed"
    exit 1
  fi
}

# Run the tests
run_tests