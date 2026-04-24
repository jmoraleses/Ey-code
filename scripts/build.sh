#!/usr/bin/env bash
# Build Ey-Code (opencode fork) for the current platform
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

if ! command -v bun >/dev/null 2>&1; then
  echo "bun is required. Install: curl -fsSL https://bun.sh/install | bash"
  exit 1
fi

echo "==> Installing dependencies..."
bun install

echo
echo "==> Building Ey-Code binary..."
bun run --cwd packages/opencode build

ARCH=$(uname -m)
case "$ARCH" in
  arm64)  TARGET="opencode-darwin-arm64" ;;
  x86_64) TARGET="opencode-darwin-x64"   ;;
  *)      echo "Unsupported arch: $ARCH"; exit 1 ;;
esac

BIN="$PROJECT_DIR/packages/opencode/dist/$TARGET/bin/opencode"

if [ ! -x "$BIN" ]; then
  echo "Binary not found at $BIN"
  exit 1
fi

echo
echo "==> Build complete."
echo "    Binary: $BIN"
echo "    Size:   $(du -h "$BIN" | awk '{print $1}')"
echo "    Version: $("$BIN" --version)"
echo
echo "Run ./scripts/install-mac.sh to install it as \`ey-code\`."
