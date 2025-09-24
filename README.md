# Qwen3-Omni-30B-A3B-Instruct vLLM Docker

Docker container for running Qwen3-Omni-30B-A3B-Instruct model using vLLM.

## Quick Start

1. **Download the model** (optional, can use HF cache):
   ```bash
   ./download-model.sh
   ```

2. **Build the Docker image**:
   ```bash
   docker build -t qwen3-omni-vllm:local .
   ```

3. **Start the container**:
   ```bash
   ./start.sh
   ```

4. **Check status**:
   ```bash
   ./status.sh
   ```

5. **Stop the container**:
   ```bash
   ./stop.sh
   ```

## Configuration

Edit `config.sh` to modify:
- Container name and image
- Port mappings
- Network settings
- Model repository

## Requirements

- Docker with GPU support
- NVIDIA drivers
- At least 60GB RAM (for 30B model)
- CUDA-compatible GPU with sufficient VRAM

## API Access

Once running, the API is available at:
- **Base URL**: `http://localhost:8901`
- **Health Check**: `http://localhost:8901/health`
- **OpenAI-compatible**: `http://localhost:8901/v1/chat/completions`

## Environment Variables

- `HF_HOME`: Hugging Face cache directory (recommended)
- `HF_TOKEN`: Hugging Face token for private models