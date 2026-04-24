#!/usr/bin/env bash
# Ey-Code launcher wrapper
#
# Ensures the local MLX model servers are running before invoking the real
# ey-code binary. Started servers survive the ey-code session (daemonized)
# so subsequent runs are instant.
#
# Installed alongside the binary at:
#   ~/.local/bin/ey-code           ← this wrapper
#   ~/.local/libexec/ey-code-bin   ← the actual binary

set -euo pipefail

# Resolve the real binary (installed at libexec; fallback: project dist)
PROJECT_DIR="$(dirname "$(dirname "$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")")")" 2>/dev/null || PROJECT_DIR=""
REAL_BIN=""
for candidate in \
    "$HOME/.local/libexec/ey-code-bin" \
    "/usr/local/libexec/ey-code-bin" \
    "$PROJECT_DIR/packages/opencode/dist/opencode-darwin-arm64/bin/opencode"; do
  if [ -x "$candidate" ]; then REAL_BIN="$candidate"; break; fi
done

if [ -z "$REAL_BIN" ]; then
  echo "ey-code: binary not found; run ./scripts/install-mac.sh" >&2
  exit 127
fi

# Models directory (set via env or defaults to ~/Documents/.eycode/models)
MODELS_DIR="${EY_CODE_MODELS_DIR:-$HOME/Documents/.eycode/models}"
MAIN_MODEL="$MODELS_DIR/LFM2-350M-4bit"
CODER_MODEL="$MODELS_DIR/LFM2.5-1.2B-Instruct-4bit"
TOOL_MODEL="$MODELS_DIR/LFM2-1.2B-Tool-MLX-4bit"

LOG_DIR="$HOME/.local/state/ey-code"
mkdir -p "$LOG_DIR"

# --cloud flag: skip MLX, use Anthropic
CLOUD=false
for a in "$@"; do [[ "$a" == "--cloud" ]] && CLOUD=true; done
if $CLOUD; then
  ARGS=()
  for a in "$@"; do [[ "$a" != "--cloud" ]] && ARGS+=("$a"); done
  exec "$REAL_BIN" "${ARGS[@]}"
fi

# Check mlx_lm
if ! python3 -c "import mlx_lm" 2>/dev/null; then
  echo "ey-code: mlx_lm not installed. Install with:  pip install mlx-lm" >&2
  echo "       or run with --cloud to use Anthropic instead." >&2
  exit 1
fi

# Ensure models are present
for m in "$MAIN_MODEL" "$CODER_MODEL" "$TOOL_MODEL"; do
  if [ ! -d "$m" ]; then
    echo "ey-code: model missing: $m" >&2
    echo "       Download with: ey-code-download-models" >&2
    echo "       Or run with --cloud for Anthropic mode." >&2
    exit 1
  fi
done

start_if_down() {
  local port="$1" model="$2" logname="$3"
  if curl -s --max-time 1 "http://127.0.0.1:$port/v1/models" >/dev/null 2>&1; then
    return 0  # already up
  fi
  # lsof -ti cleans leftover half-dead listeners
  lsof -ti:"$port" 2>/dev/null | xargs kill -9 2>/dev/null || true
  nohup python3 -m mlx_lm.server \
    --model "$model" \
    --port "$port" \
    --host 127.0.0.1 \
    > "$LOG_DIR/$logname.log" 2>&1 &
  disown || true
}

start_lazy_proxy() {
  local port="$1" model="$2" logname="$3"
  if curl -s --max-time 1 "http://127.0.0.1:$port/v1/models" >/dev/null 2>&1; then return 0; fi
  lsof -ti:"$port" 2>/dev/null | xargs kill -9 2>/dev/null || true
  local proxy="$HOME/.local/libexec/ey-code-lazy-mlx.py"
  [ -x "$proxy" ] || proxy="$PROJECT_DIR/scripts/lazy-mlx.py"
  nohup python3 "$proxy" "$port" "$model" \
    > "$LOG_DIR/$logname.log" 2>&1 &
  disown || true
}

echo "ey-code: ensuring local MLX servers..." >&2
start_if_down    8080 "$MAIN_MODEL"  mlx-main
start_lazy_proxy 8081 "$CODER_MODEL" mlx-coder
start_lazy_proxy 8082 "$TOOL_MODEL"  mlx-tools

# Wait up to 60s for the eager main server
for port in 8080; do
  for i in $(seq 1 60); do
    if curl -s --max-time 1 "http://127.0.0.1:$port/v1/models" >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done
done

# Ports 8081 and 8082 are lazy proxies — they accept connections immediately
echo "ey-code: ready" >&2
exec "$REAL_BIN" "$@"
