#!/usr/bin/env bash
# Launch Ey-Code via "$PROJECT_DIR/packages/opencode/dist/opencode-darwin-arm64/bin/opencode"
# Usage:
#   ./scripts/start.sh            — local mode (MLX models, fully offline)
#   ./scripts/start.sh --cloud    — cloud mode (Anthropic API, needs ANTHROPIC_API_KEY)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

CLOUD_MODE=false
for arg in "$@"; do
  [[ "$arg" == "--cloud" ]] && CLOUD_MODE=true
done

if $CLOUD_MODE; then
  if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    echo "ANTHROPIC_API_KEY not set."
    exit 1
  fi
  echo "Starting Ey-Code (cloud / Anthropic)..."
  # Override model to use Anthropic
  OPENCODE_MODEL="anthropic/claude-sonnet-4-6" "$PROJECT_DIR/packages/opencode/dist/opencode-darwin-arm64/bin/opencode"
else
  echo "Starting Ey-Code (local MLX)..."

  # Start servers if not already running
  if ! curl -s http://127.0.0.1:8080/v1/models > /dev/null 2>&1; then
    bash "$SCRIPT_DIR/start-mlx.sh"
  else
    echo "MLX servers already running."
  fi

  "$PROJECT_DIR/packages/opencode/dist/opencode-darwin-arm64/bin/opencode"
fi
