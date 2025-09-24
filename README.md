# Qwen3-Omni vLLM Docker

Super-simple docker container setup for running Qwen3-Omni models (Instruct, Thinking, Captioner) using a custom version of vLLM with Qwen patches and flash attention.

## Supported Models

- **instruct** (default): `Qwen/Qwen3-Omni-30B-A3B-Instruct`
- **thinking**: `Qwen/Qwen3-Omni-30B-A3B-Thinking` 
- **captioner**: `Qwen/Qwen3-Omni-30B-A3B-Captioner`

## Quick Start

1. **Make scripts executable**:
   ```bash
   make setup
   ```

2. **Build the Docker image** (defaults to instruct):

  Please note: The size of the base image is substantial due to a full CUDA toolkit installation. Ensure you have sufficient disk space - all layers take ~16GiB.
  A fresh build (without cache) may take 15-30 minutes depending on your internet speed and system performance.

   ```bash
   sudo make build
   # or specify variant: make build MODEL_VARIANT=thinking
   ```

3. **Download the model** (optional, can use HF cache):
   ```bash
   make download
   # or specify variant: make download MODEL_VARIANT=thinking
   ```

4. **Start the container**:
   ```bash
   make start
   # or specify variant: make start MODEL_VARIANT=thinking
   ```

5. **Check status**:
   ```bash
   make status
   # or specify variant: make status MODEL_VARIANT=thinking
   ```

6. **Stop the container**:
   ```bash
   make stop
   # or specify variant: make stop MODEL_VARIANT=thinking
   ```

7. **Test vLLM and Model (e2e test using cURL)**:
   ```bash
   make api-test
   # or specify variant: make api-test MODEL_VARIANT=thinking
   ```

## Model Variant Usage

### Method 1: Make with Arguments (Recommended)
```bash
# Build specific variant
make build MODEL_VARIANT=thinking
make start MODEL_VARIANT=thinking
make status MODEL_VARIANT=thinking

# Build all variants
make build-all
```

### Method 2: Direct Script Arguments
```bash
# Make executable first
chmod +x *.sh

# Use scripts with arguments
./build.sh thinking
./start.sh thinking
./status.sh thinking
./stop.sh thinking
./api-test.sh thinking
```

### Method 3: Environment Variable
```bash
# Set variant for all subsequent commands
export MODEL_VARIANT=captioner
make build
make start
make status
```

## Make Commands

- `make help` - Show all available commands and examples
- `make setup` - Make scripts executable
- `make build [MODEL_VARIANT=x]` - Build Docker image for variant
- `make build-all` - Build all model variants (instruct, thinking, captioner)
- `make download [MODEL_VARIANT=x]` - Download model files
- `make start [MODEL_VARIANT=x]` - Start container
- `make stop [MODEL_VARIANT=x]` - Stop container
- `make status [MODEL_VARIANT=x]` - Check container status
- `make clean [MODEL_VARIANT=x]` - Remove container and image for variant
- `make clean-all` - Remove all containers and images

## Script Help

All scripts support help with `-h` or `--help`:

```bash
./build.sh --h
./start.sh -h
./stop.sh --h
./status.sh -h
./download-model.sh -h
```

## Configuration

The configuration is automatically managed via `config.sh` based on the model variant:

- **Container names**: `qwen3-omni-30b-a3b-{variant}` (e.g., `qwen3-omni-30b-a3b-thinking`)
- **Image tags**: `qwen3-omni-vllm:{variant}` (e.g., `qwen3-omni-vllm:captioner`)
- **Model repositories**: `Qwen/Qwen3-Omni-30B-A3B-{Variant}` (e.g., `Qwen/Qwen3-Omni-30B-A3B-Thinking`)
- **Network aliases**: Include variant for isolation
- **Port**: All variants use port 8901 (only one can run at a time)

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

### Model Configuration
- **`MODEL_VARIANT`**: Model variant to use (instruct, thinking, captioner)
  - Default: `instruct`
  - Example: `export MODEL_VARIANT=thinking`
  - Can be overridden by script arguments

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

## Example Workflows

### Single Model Workflow
```bash
# Set up for thinking model
export HF_HOME="/path/to/your/hf/cache"
export HF_TOKEN="hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Build and run specific variant
make setup
make build MODEL_VARIANT=thinking
make download MODEL_VARIANT=thinking
make start MODEL_VARIANT=thinking

# Check status
make status MODEL_VARIANT=thinking

# Stop when done
make stop MODEL_VARIANT=thinking
```

### Multi-Model Workflow
```bash
# Build all variants
make setup
make build-all

# Run different models as needed
make start MODEL_VARIANT=instruct
# ... use instruct model ...
make stop MODEL_VARIANT=instruct

make start MODEL_VARIANT=thinking
# ... use thinking model ...
make stop MODEL_VARIANT=thinking

make start MODEL_VARIANT=captioner
# ... use captioner model ...
make stop MODEL_VARIANT=captioner
```

### Development Workflow
```bash
# Use direct scripts for development
chmod +x *.sh

./build.sh thinking
./start.sh thinking
./status.sh thinking

# Check logs
docker logs -f qwen3-omni-30b-a3b-thinking

# Stop and clean up
./stop.sh thinking
```

## Troubleshooting

- **Script permissions**: `chmod +x *.sh` or `make setup`
- **Makefile issues**: Use direct script commands instead
- **Container logs**: `docker logs -f qwen3-omni-30b-a3b-{variant}`
- **Authentication**: Check your HF_TOKEN permissions for the specific model
- **Cache issues**: Verify HF_HOME directory permissions and disk space
- **Port conflicts**: Only one model variant can run at a time (all use port 8901)
- **GPU memory**: Ensure sufficient VRAM for the 30B model
- **Invalid variant**: Must be one of: instruct, thinking, captioner

## Advanced Usage

### Custom Model Repository
```bash
# Override model repo in environment
export MODEL_REPO="your-org/custom-qwen3-omni-model"
./start.sh
```

### Different Cache Locations
```bash
# Use different cache for each variant
HF_HOME="/cache/instruct" ./start.sh instruct
HF_HOME="/cache/thinking" ./start.sh thinking
```

### Network Isolation
Each variant gets its own network alias, allowing you to run multiple containers in different networks if needed.