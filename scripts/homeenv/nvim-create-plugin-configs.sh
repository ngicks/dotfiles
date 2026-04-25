#!/usr/bin/env bash

set -e

# Create plugin config directories under ~/.dotfiles/config/nvim
# Run this before tagging commits for devenv image creation
#
# Uses XDG_CONFIG_HOME hack so vim.fn.stdpath("config") returns
# ~/.dotfiles/config/nvim instead of ~/.config/nvim

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

XDG_CONFIG_HOME="$DOTFILES_DIR/config" nvim --headless \
  -c "lua require('ngcfg.plugins.funcs').auto_create(require('ngcfg.plugins.list'))" \
  -c "qa"

echo "Plugin config directories created/verified"
