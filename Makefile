.PHONY: build start stop status download clean help setup build-all clean-all

# Default model variant
MODEL_VARIANT ?= instruct

help:
	@echo "Available commands:"
	@echo "  make setup                    - Make scripts executable"
	@echo "  make build [MODEL_VARIANT=x]  - Build Docker image"
	@echo "  make build-all                - Build all model variants"
	@echo "  make download [MODEL_VARIANT=x] - Download model files"
	@echo "  make start [MODEL_VARIANT=x]  - Start container"
	@echo "  make stop [MODEL_VARIANT=x]   - Stop container"
	@echo "  make status [MODEL_VARIANT=x] - Check container status"
	@echo "  make clean [MODEL_VARIANT=x]  - Remove container and image"
	@echo "  make clean-all                - Remove all variants"
	@echo "  make test-api [MODEL_VARIANT=x] - Test vLLM and Model (e2e test using cURL)"
	@echo ""
	@echo "Model variants:"
	@echo "  instruct   -> Qwen3-Omni-30B-A3B-Instruct (default)"
	@echo "  thinking   -> Qwen3-Omni-30B-A3B-Thinking"
	@echo "  captioner  -> Qwen3-Omni-30B-A3B-Captioner"
	@echo ""
	@echo "Examples:"
	@echo "  make build                         # Build instruct variant"
	@echo "  make build MODEL_VARIANT=thinking  # Build thinking variant"
	@echo "  make start MODEL_VARIANT=captioner # Start captioner variant"
	@echo "  ./build.sh thinking                # Direct script usage"
	@echo "  ./start.sh captioner               # Direct script usage"

setup:
	chmod +x *.sh

build:
	./build.sh $(MODEL_VARIANT)

build-all:
	./build.sh instruct
	./build.sh thinking
	./build.sh captioner

download:
	./download.sh $(MODEL_VARIANT)

start:
	./start.sh $(MODEL_VARIANT)

stop:
	./stop.sh $(MODEL_VARIANT)

status:
	./status.sh $(MODEL_VARIANT)

clean:
	./stop.sh $(MODEL_VARIANT) || true
	docker rmi qwen3-omni-vllm:$(MODEL_VARIANT) || true

clean-all:
	./stop.sh instruct || true
	./stop.sh thinking || true
	./stop.sh captioner || true
	docker rmi qwen3-omni-vllm:instruct || true
	docker rmi qwen3-omni-vllm:thinking || true
	docker rmi qwen3-omni-vllm:captioner || true

test-api:
	./test-api.sh $(MODEL_VARIANT)