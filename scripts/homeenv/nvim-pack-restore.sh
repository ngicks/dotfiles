#!/usr/bin/env bash

set -euo pipefail

nvim --headless \
  "+lua vim.pack.update(nil, { target = 'lockfile' })" \
  "+write" \
  "+quitall"
