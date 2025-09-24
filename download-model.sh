#!/usr/bin/env bash
set -euo pipefail

# -------- Config (overridable via env) --------
MODEL_REPO="${MODEL_REPO:-Qwen/Qwen3-Omni-30B-A3B-Instruct}"
# Optional: if set, files also materialize into this directory; otherwise use HF cache only
MODEL_DIR="${MODEL_DIR:-}"
VENV_DIR="${VENV_DIR:-.venv}"

# Optional HF overrides; if empty → use HF defaults
HF_HOME="${HF_HOME:-}"
TRANSFORMERS_CACHE="${TRANSFORMERS_CACHE:-}"
HUGGINGFACE_HUB_CACHE="${HUGGINGFACE_HUB_CACHE:-}"

# -------- Setup venv & deps --------
echo "Setting up Python virtual environment in: $VENV_DIR..."

python3 -m venv "$VENV_DIR"
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"
pip install -U pip wheel >/dev/null
if [[ -f requirements.txt ]]; then
  pip install -r requirements.txt >/dev/null
else
  pip install "huggingface_hub[cli]>=0.24.0" >/dev/null
fi

# Export only if provided, so HF falls back to defaults otherwise
[ -n "$HF_HOME" ] && export HF_HOME
[ -n "$TRANSFORMERS_CACHE" ] && export TRANSFORMERS_CACHE
[ -n "$HUGGINGFACE_HUB_CACHE" ] && export HUGGINGFACE_HUB_CACHE

# Determine the effective HF hub cache dir from the library itself
EFFECTIVE_CACHE_DIR="$(python - <<'PY'
from huggingface_hub.constants import HF_HUB_CACHE
print(HF_HUB_CACHE)
PY
)"

# Resolve target path text
TARGET_TEXT="HF cache (internal hashed layout)"
DL_ARGS=( "$MODEL_REPO" )
if [[ -n "$MODEL_DIR" ]]; then
  mkdir -p "$MODEL_DIR"
  DL_ARGS+=( "--local-dir" "$MODEL_DIR" )
  TARGET_TEXT="$MODEL_DIR (explicit local directory)"
fi

# -------- Print config & confirm --------
echo "=== Hugging Face download configuration ==="
echo "  MODEL_REPO:              $MODEL_REPO"
echo "  HF_HOME:                 ${HF_HOME:-<default>}"
echo "  TRANSFORMERS_CACHE:      ${TRANSFORMERS_CACHE:-<default>}"
echo "  HUGGINGFACE_HUB_CACHE:   ${HUGGINGFACE_HUB_CACHE:-<default>}"
echo "  Effective HF hub cache:  $EFFECTIVE_CACHE_DIR"
echo "  Target materialization:  $TARGET_TEXT"
echo "==========================================="

read -r -p "Proceed with download? [y/N] " ans
case "${ans:-N}" in
  y|Y) ;;
  *) echo "Aborted."; deactivate; exit 1 ;;
esac

# -------- Token handling (prompt if missing) --------
if [[ -z "${HF_TOKEN:-}" ]]; then
  echo "No HF_TOKEN found in environment."
  read -r -p "Enter your Hugging Face token (leave empty for none): " HF_TOKEN
fi

if [[ -n "${HF_TOKEN:-}" ]]; then
  echo "Logging into Hugging Face with provided token…"
  hf auth login --token "$HF_TOKEN" --add-to-git-credential || true
else
  echo "No token provided — proceeding for public assets only."
fi

# -------- Download --------
echo "Starting download (resumable)..."
hf download "${DL_ARGS[@]}"

echo "Done."
echo "Cached files live under: $EFFECTIVE_CACHE_DIR"
if [[ -n "$MODEL_DIR" ]]; then
  echo "Explicit local directory populated at: $MODEL_DIR"
fi

deactivate
