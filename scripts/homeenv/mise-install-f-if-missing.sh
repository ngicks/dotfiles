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

while IFS=$'\t' read -r tool install_path; do
  [ -n "$tool" ] || continue
  if check_dir "$install_path/bin"; then
    echo "ok: $tool"
  else
    echo "reinstalling: $tool"
    mise install -f "$tool" || true
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
    | "\($tool)\t\(.install_path // "")"
  '
)
