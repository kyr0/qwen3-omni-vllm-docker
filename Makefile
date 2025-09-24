.PHONY: build start stop status download clean help setup

help:
	@echo "Available commands:"
	@echo "  make setup     - Make scripts executable"
	@echo "  make build     - Build Docker image"
	@echo "  make download  - Download model files"
	@echo "  make start     - Start container"
	@echo "  make stop      - Stop container"
	@echo "  make status    - Check container status"
	@echo "  make clean     - Remove container and image"

setup:
	chmod +x *.sh

build:
	./build.sh

download:
	./download-model.sh

start:
	./start.sh

stop:
	./stop.sh

status:
	./status.sh

clean:
	./stop.sh || true
	docker rmi qwen3-omni-vllm:local || true