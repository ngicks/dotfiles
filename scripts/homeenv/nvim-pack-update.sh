#!/usr/bin/env bash

set -euo pipefail

dir=$(cd "$(dirname "$0")/../.." && pwd)

# During install/upgrade this runs in a shell without mise activation, so
# mise-managed tools nvim needs at restore time (tree-sitter for
# nvim-treesitter parser builds) are not on PATH. Shims cover that.
mise_shims="${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims"
if [ -d "$mise_shims" ]; then
  export PATH="$mise_shims:$PATH"
fi

XDG_CONFIG_HOME="$dir/config" \
XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/nvim-cache}" \
XDG_STATE_HOME="${XDG_STATE_HOME:-/tmp/nvim-state}" \
nvim --headless \
  "+lua require('ngpack.lock').prune_broken()" \
  "+quitall"

# prune_broken runs in its own nvim above: startup has already vim.pack.add-ed
# every plugin, so deleting a broken dir in the same session leaves vim.pack's
# in-memory state pointing at a gone directory and a later vim.pack.update
# crashes on it. A fresh nvim below re-installs the pruned ones cleanly.
XDG_CONFIG_HOME="$dir/config" \
XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/nvim-cache}" \
XDG_STATE_HOME="${XDG_STATE_HOME:-/tmp/nvim-state}" \
nvim --headless \
  "+PackLockPruneOrphans" \
  "+PackLockPruneDesync" \
  "+lua vim.pack.add(require(\"ngpack\").list_pack(), { confirm = false })" \
  "+lua vim.pack.update()" \
  "+write" \
  "+quitall"

XDG_CONFIG_HOME="$dir/config" \
XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/nvim-cache}" \
XDG_STATE_HOME="${XDG_STATE_HOME:-/tmp/nvim-state}" \
nvim --headless \
  "+quitall"

# vim.pack.add reports per-plugin install errors via vim.notify and keeps
# going, so a plugin can be left cloned but never checked out (only .git on
# disk) while nvim still exits 0. Fail loudly here instead.
XDG_CONFIG_HOME="$dir/config" \
XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/nvim-cache}" \
XDG_STATE_HOME="${XDG_STATE_HOME:-/tmp/nvim-state}" \
nvim --headless \
  "+lua local bad = require('ngpack.lock').verify_installed(); if #bad > 0 then io.stderr:write('broken plugin checkouts:\n  ' .. table.concat(bad, '\n  ') .. '\n') vim.cmd('cquit 1') end" \
  "+quitall"
