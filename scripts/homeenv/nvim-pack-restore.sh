#!/usr/bin/env bash

set -euo pipefail


dir=$(cd "$(dirname "$0")/../.." && pwd)

XDG_CONFIG_HOME="$dir/config" \
XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/nvim-cache}" \
XDG_STATE_HOME="${XDG_STATE_HOME:-/tmp/nvim-state}" \
nvim --headless \
  "+PackLockPruneOrphans" \
  "+lua vim.pack.update(nil, { target = 'lockfile' })" \
  "+write" \
  "+quitall"
