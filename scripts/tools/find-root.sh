#!/usr/bin/env bash
# find-root: Find project root by walking parent directories for markers.
# Uses MoonBit WASM to compute parent paths, then checks for markers in shell.
#
# Usage: find-root [start-path]
# Prints the project root path to stdout, exits non-zero if not found.

set -euo pipefail

MOON_HOME="${MOON_HOME:-$HOME/.local/share/moonbit}"
WASM="$HOME/.dotfiles/tools/target/wasm-gc/release/build/src/find_root/find_root.wasm"
MARKERS=(".git" ".claude" "AGENTS.md")

find_root_shell() {
  local dir="${1:-$(pwd)}"
  # Resolve to absolute path
  dir="$(cd "$dir" 2>/dev/null && pwd)" || {
    echo "error: cannot resolve path: $1" >&2
    return 1
  }
  while true; do
    for marker in "${MARKERS[@]}"; do
      if [[ -e "$dir/$marker" ]]; then
        echo "$dir"
        return 0
      fi
    done
    local parent
    parent="$(dirname "$dir")"
    if [[ "$parent" == "$dir" ]]; then
      break
    fi
    dir="$parent"
  done
  echo "error: project root not found" >&2
  return 1
}

# Try MoonBit WASM if available, fall back to pure shell
if [[ -f "$WASM" ]] && command -v "$MOON_HOME/bin/moonrun" &>/dev/null; then
  while IFS= read -r dir; do
    for marker in "${MARKERS[@]}"; do
      if [[ -e "$dir/$marker" ]]; then
        echo "$dir"
        exit 0
      fi
    done
  done < <("$MOON_HOME/bin/moonrun" "$WASM" "$@")
  echo "error: project root not found" >&2
  exit 1
else
  find_root_shell "$@"
fi
