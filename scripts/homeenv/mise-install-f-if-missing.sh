#!/usr/bin/env bash

set -euo pipefail

# Stdin redirected from /dev/null so server-style binaries (e.g. an LSP)
# exit on EOF instead of stalling.
check_dir() {
  local bin_dir="$1"
  [ -d "$bin_dir" ] || return 1

  (
    shopt -s nullglob
    saw_bin=0
    for bin in "$bin_dir"/*; do
      [ -f "$bin" ] && [ -x "$bin" ] || continue
      saw_bin=1
      "$bin" --version </dev/null >/dev/null 2>&1 && continue
      "$bin" --help    </dev/null >/dev/null 2>&1 && continue
      "$bin" version   </dev/null >/dev/null 2>&1 && continue
      "$bin" help      </dev/null >/dev/null 2>&1 && continue
      exit 1
    done
    [ "$saw_bin" -eq 1 ]
  )
}

# Ask mise for each tool's effective bin dirs rather than assuming
# <install_path>/bin: backends differ (npm's embedded-aube installs since
# ~2026.7.14 keep bins in node_modules/.bin with no top-level bin/), and
# `mise bin-paths` runs the backend's own layout resolution.
check_tool() {
  local tool="$1" bin_dir
  while IFS= read -r bin_dir; do
    [ -n "$bin_dir" ] || continue
    check_dir "$bin_dir" && return 0
  done < <(mise bin-paths "$tool" 2>/dev/null)
  return 1
}

while IFS= read -r tool; do
  [ -n "$tool" ] || continue
  if check_tool "$tool"; then
    echo "ok: $tool"
  else
    echo "reinstalling: $tool"
    mise install --locked -f "$tool" || true
  fi
done < <(
  mise ls -J | jq -r '
    to_entries[]
    | select(.key | startswith("npm:")
                 or startswith("go:")
                 or startswith("cargo:")
                 or startswith("pipx:"))
    | .key as $tool
    | .value[]
    | select(.active == true)
    | $tool
  '
)
