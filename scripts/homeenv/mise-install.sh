#!/usr/bin/env bash

set -euo pipefail

run_in_new_shell=$(cd $(dirname $0) && pwd -P)/run-in-new-interactive-shell.sh
mise_install_f=$(cd $(dirname $0) && pwd -P)/mise-install-f-if-missing.sh

echo ""
echo "mise install"
echo ""

IN_CONTAINER=1 \
  MISE_GLOBAL_CONFIG_FILE=$HOME/.dotfiles/config/mise/mise.toml \
  $run_in_new_shell "$HOME/.dotfiles/config/mise" mise install

echo ""
echo "mise install -f if missing"
echo ""

IN_CONTAINER=1 \
  MISE_GLOBAL_CONFIG_FILE=$HOME/.dotfiles/config/mise/mise.toml \
  $run_in_new_shell "$HOME/.dotfiles/config/mise" $mise_install_f

echo ""
echo "mise prune"
echo ""

IN_CONTAINER=1 \
  MISE_GLOBAL_CONFIG_FILE=$HOME/.dotfiles/config/mise/mise.toml \
  $run_in_new_shell "$HOME/.dotfiles/config/mise" mise prune -y
