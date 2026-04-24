#!/usr/bin/env bash
# Download all local MLX models from Hugging Face
set -euo pipefail

MODELS_DIR="${EY_CODE_MODELS_DIR:-$HOME/Documents/.eycode/models}"

mkdir -p "$MODELS_DIR"

echo "Downloading models to $MODELS_DIR"
echo

python3 - <<EOF
from huggingface_hub import snapshot_download
import os

models_dir = "$MODELS_DIR"

print("1/3 Downloading mlx-community/LFM2-350M-4bit...")
snapshot_download(
    "mlx-community/LFM2-350M-4bit",
    local_dir=os.path.join(models_dir, "LFM2-350M-4bit"),
)
print("    Done.")

print("2/3 Downloading mlx-community/LFM2.5-1.2B-Instruct-4bit...")
snapshot_download(
    "mlx-community/LFM2.5-1.2B-Instruct-4bit",
    local_dir=os.path.join(models_dir, "LFM2.5-1.2B-Instruct-4bit"),
)
print("    Done.")

print("3/3 Downloading Unravler/LFM2-1.2B-Tool-MLX-4bit...")
snapshot_download(
    "Unravler/LFM2-1.2B-Tool-MLX-4bit",
    local_dir=os.path.join(models_dir, "LFM2-1.2B-Tool-MLX-4bit"),
)
print("    Done.")

print()
print("All models ready in $MODELS_DIR")
EOF
