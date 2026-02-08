#!/usr/bin/env bash
# Build MoonBit tools/ WASM artifacts.

set -euo pipefail

export MOON_HOME="${MOON_HOME:-$HOME/.local/share/moonbit}"
TOOLS_DIR="$(cd "$(dirname "$0")/../../tools" && pwd)"

if [[ ! -x "$MOON_HOME/bin/moon" ]]; then
  echo "error: MoonBit not installed. Run: scripts/homeenv/moonbit-install.sh" >&2
  exit 1
fi

cd "$TOOLS_DIR"

echo "Updating MoonBit dependencies..."
"$MOON_HOME/bin/moon" update

echo "Building tools (wasm-gc, release)..."
"$MOON_HOME/bin/moon" build --target wasm-gc --release

echo "Build complete. Artifacts:"
find target/wasm-gc/release/build -name '*.wasm' 2>/dev/null || echo "  (none found)"
