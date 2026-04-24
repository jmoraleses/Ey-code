#!/usr/bin/env bash
# Start local MLX model servers
#   Port 8080 — main model:  mlx-community/LFM2-350M-4bit        (eager)
#   Port 8081 — coder model: mlx-community/LFM2.5-1.2B-Instruct-4bit (lazy)
#   Port 8082 — tool model:  mlx-community/LFM2-1.2B-Tool-MLX-4bit (lazy)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODELS_DIR="$HOME/Documents/.eycode/models"

MAIN_MODEL="$MODELS_DIR/LFM2-350M-4bit"
CODER_MODEL="$MODELS_DIR/LFM2.5-1.2B-Instruct-4bit"
TOOL_MODEL="$MODELS_DIR/LFM2-1.2B-Tool-MLX-4bit"

for m in "$MAIN_MODEL" "$CODER_MODEL" "$TOOL_MODEL"; do
  if [ ! -d "$m" ]; then
    echo "Model not found: $m"
    echo "Run: ./scripts/download-models.sh"
    # We don't exit here to allow starting whatever is available, 
    # but lazy proxy will fail if model is missing at runtime.
  fi
done

# Kill any existing servers on those ports (including lazy proxy backends on +10000)
for port in 8080 8081 8082 18081 18082; do
  lsof -ti:$port | xargs kill -9 2>/dev/null || true
done
sleep 0.5

echo "Starting MLX main model on port 8080 (eager)..."
python -m mlx_lm.server \
  --model "$MAIN_MODEL" \
  --port 8080 \
  --host 127.0.0.1 \
  > /tmp/mlx-main.log 2>&1 &
echo "  PID $! — logs: /tmp/mlx-main.log"

echo "Starting lazy proxy on port 8081 (coder loads on first request)..."
python "$SCRIPT_DIR/lazy-mlx.py" 8081 "$CODER_MODEL" \
  > /tmp/mlx-coder.log 2>&1 &
echo "  PID $! — logs: /tmp/mlx-coder.log"

echo "Starting lazy proxy on port 8082 (tools load on first request)..."
python "$SCRIPT_DIR/lazy-mlx.py" 8082 "$TOOL_MODEL" \
  > /tmp/mlx-tools.log 2>&1 &
echo "  PID $! — logs: /tmp/mlx-tools.log"

echo
echo "Waiting for eager main server to be ready..."
for i in $(seq 1 30); do
  if curl -s "http://127.0.0.1:8080/v1/models" > /dev/null 2>&1; then
    echo "  port 8080 ready"
    break
  fi
  sleep 1
done

echo "  port 8081 lazy proxy ready (1.2B)"
echo "  port 8082 lazy proxy ready (Tool)"
echo
echo "Servers running. Run ./scripts/start.sh to launch Ey-Code."
