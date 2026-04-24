#!/usr/bin/env bash
# Install Ey-Code on macOS
#
# Installs the compiled binary as /usr/local/bin/ey-code (and opencode alias).
# If /usr/local/bin is not writable, falls back to ~/.local/bin.
# Re-runs the build if the binary is missing.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This installer only supports macOS. Detected: $(uname -s)"
  exit 1
fi

ARCH=$(uname -m)
case "$ARCH" in
  arm64)  TARGET="opencode-darwin-arm64" ;;
  x86_64) TARGET="opencode-darwin-x64"   ;;
  *)      echo "Unsupported arch: $ARCH"; exit 1 ;;
esac

BIN_SRC="$PROJECT_DIR/packages/opencode/dist/$TARGET/bin/opencode"

if [ ! -x "$BIN_SRC" ]; then
  echo "Binary not found; running build..."
  bash "$SCRIPT_DIR/build.sh"
fi

# Pick an install prefix
#   default: ~/.local/bin (no sudo)
#   --system flag: /usr/local/bin (requires sudo)
SYSTEM_INSTALL=false
for arg in "$@"; do
  [[ "$arg" == "--system" ]] && SYSTEM_INSTALL=true
done

if $SYSTEM_INSTALL; then
  PREFIX=/usr/local/bin
  if [ -w "$PREFIX" ]; then
    USE_SUDO=""
  else
    USE_SUDO="sudo"
    echo "System install — sudo will be required."
  fi
else
  PREFIX="$HOME/.local/bin"
  USE_SUDO=""
  mkdir -p "$PREFIX"
fi

echo "==> Installing to $PREFIX"

# libexec holds the real binary + helper; bin holds the wrapper entry point
if $SYSTEM_INSTALL; then
  LIBEXEC="/usr/local/libexec"
else
  LIBEXEC="$HOME/.local/libexec"
  mkdir -p "$LIBEXEC"
fi

# 1) Install the actual binary to libexec
$USE_SUDO cp "$BIN_SRC" "$LIBEXEC/ey-code-bin"
$USE_SUDO chmod +x "$LIBEXEC/ey-code-bin"

# 2) Install the lazy-mlx proxy helper
$USE_SUDO cp "$SCRIPT_DIR/lazy-mlx.py" "$LIBEXEC/ey-code-lazy-mlx.py"
$USE_SUDO chmod +x "$LIBEXEC/ey-code-lazy-mlx.py"

# 3) Install the wrapper as ey-code (auto-starts MLX servers on first run)
$USE_SUDO cp "$SCRIPT_DIR/ey-code-wrapper.sh" "$PREFIX/ey-code"
$USE_SUDO chmod +x "$PREFIX/ey-code"

# 4) opencode alias → ey-code wrapper
$USE_SUDO ln -sf "$PREFIX/ey-code" "$PREFIX/opencode"

# 5) Download-models helper (so `ey-code` can suggest a clear next step)
$USE_SUDO cp "$SCRIPT_DIR/download-models.sh" "$LIBEXEC/ey-code-download-models"
$USE_SUDO chmod +x "$LIBEXEC/ey-code-download-models"
$USE_SUDO ln -sf "$LIBEXEC/ey-code-download-models" "$PREFIX/ey-code-download-models"

# 6) Global identity: AGENTS.md + skills live in ~/.config/ey-code
GLOBAL_CONFIG="$HOME/.config/ey-code"
mkdir -p "$GLOBAL_CONFIG"
cp "$PROJECT_DIR/AGENTS.md" "$GLOBAL_CONFIG/AGENTS.md"
rm -rf "$GLOBAL_CONFIG/skills"
cp -R "$PROJECT_DIR/skills" "$GLOBAL_CONFIG/skills"
if [ ! -f "$GLOBAL_CONFIG/opencode.json" ]; then
  cp "$PROJECT_DIR/opencode.json" "$GLOBAL_CONFIG/opencode.json"
fi

# 7) Models directory (symlinked to project models/ if present, so downloads are shared)
MODELS_LINK="$HOME/.local/share/ey-code/models"
mkdir -p "$(dirname "$MODELS_LINK")"
if [ -d "$PROJECT_DIR/models" ] && [ ! -e "$MODELS_LINK" ]; then
  ln -s "$PROJECT_DIR/models" "$MODELS_LINK"
fi

echo
echo "Installed:"
echo "  $PREFIX/ey-code          (launcher — auto-starts MLX servers)"
echo "  $PREFIX/opencode         (alias)"
echo "  $LIBEXEC/ey-code-bin     (actual binary)"
echo "  $GLOBAL_CONFIG/          (AGENTS.md, skills/, opencode.json)"
echo "  $MODELS_LINK             (MLX models)"
echo

if [[ ":$PATH:" != *":$PREFIX:"* ]]; then
  echo "WARNING: $PREFIX is not on your PATH."
  echo "Add to your shell rc:"
  echo "  export PATH=\"$PREFIX:\$PATH\""
  echo
fi

echo "Done. Launch with:  ey-code"
