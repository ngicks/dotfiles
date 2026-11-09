#!/usr/bin/env bash

set -euo pipefail

# mise lock runs `uv lock` for pypi tools without passing the `python` tool
# option to it, and with --no-python-downloads. uv then has to discover an
# interpreter matching requires-python by itself and does not see mise's own
# python installs, so the lock fails unless uv manages a matching version.
while IFS= read -r version; do
  [ -n "$version" ] || continue
  echo "uv python install: $version"
  # --no-bin: uv only needs to discover it; mise python stays the one on PATH.
  uv python install --no-bin "$version"
done < <(
  mise ls -J |
    jq -r 'keys[] | select(startswith("pypi:"))' |
    while IFS= read -r tool; do
      mise tool "$tool" --json | jq -r '.tool_options.python // empty'
    done |
    sort -u
)
