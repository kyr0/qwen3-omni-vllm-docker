# Qwen3-Omni vLLM Docker

Super-simple docker container setup for running Qwen3-Omni models (Instruct, Thinking, Captioner) using a custom version of vLLM with Qwen patches and flash attention.

## Quick Start

1. **Make scripts executable**:
   ```bash
   make setup
   ```

2. **Download the model** (optional, can use HF cache):
   ```bash
   make download
   ```

3. **Build the Docker image**:
   ```bash
   make build
   ```

4. **Start the container**:
   ```bash
   make start
   ```

5. **Check status**:
   ```bash
   make status
   ```

6. **Stop the container**:
   ```bash
   make stop
   ```

## Alternative Commands

If you prefer using scripts directly:

```bash
# Make executable first
chmod +x *.sh

# Then use individual scripts
./download-model.sh
./build.sh
./start.sh
./status.sh
./stop.sh
```

## Make Commands

- `make help` - Show all available commands
- `make setup` - Make scripts executable
- `make build` - Build Docker image  
- `make download` - Download model files
- `make start` - Start container
- `make stop` - Stop container
- `make status` - Check container status
- `make clean` - Remove container and image

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
- Make (for convenience commands)

## API Access

Once running, the API is available at:
- **Base URL**: `http://localhost:8901`
- **Health Check**: `http://localhost:8901/health`
- **OpenAI-compatible**: `http://localhost:8901/v1/chat/completions`

## Environment Variables

### Cache Configuration
- **`HF_HOME`**: Main Hugging Face cache directory (recommended)
  - Example: `export HF_HOME=/path/to/your/hf/cache`
  - If not set: Uses HF default (`~/.cache/huggingface`)
  
- **`TRANSFORMERS_CACHE`**: Transformers library cache directory
  - If not set: Uses HF default (typically `$HF_HOME/transformers`)
  
- **`HUGGINGFACE_HUB_CACHE`**: Hub cache for downloaded models
  - If not set: Uses HF default (typically `$HF_HOME/hub`)

### Authentication
- **`HF_TOKEN`**: Hugging Face authentication token
  - Required for: Private models, gated models, or higher rate limits
  - If not set: Script will prompt you to enter token interactively
  - Get your token from: https://huggingface.co/settings/tokens
  - Example: `export HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

### Download Configuration
- **`MODEL_REPO`**: Model repository to download (overrides config.sh)
  - Default: `Qwen/Qwen3-Omni-30B-A3B-Instruct`
  
- **`MODEL_DIR`**: Local directory for explicit model files (optional)
  - If set: Downloads model files to this directory
  - If not set: Uses HF cache with hashed layout only

## Example Setup

```bash
# Set up cache directory (recommended)
export HF_HOME="/path/to/your/hf/cache"

# Set authentication token (if needed)
export HF_TOKEN="hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Optional: explicit model directory
export MODEL_DIR="/path/to/models/qwen3-omni"

# Download and run
make setup
make download
make build
make start
```

## Troubleshooting

- If `make` commands fail, ensure scripts are executable: `chmod +x *.sh`
- If Makefile has issues, use the direct script commands instead
- Check container logs: `docker logs -f qwen3-omni-30b-a3b-instruct`
- If download fails, check your HF_TOKEN permissions for the model
- For cache issues, verify HF_HOME directory permissions and disk space