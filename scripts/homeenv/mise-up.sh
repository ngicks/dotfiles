#!/usr/bin/env bash

set -euo pipefail

run_in_container=$(cd $(dirname $0)/../../ && pwd -P)/devenv/scripts/run-devenv.sh
run_in_new_shell=$(cd $(dirname $0) && pwd -P)/run-in-new-interactive-shell.sh

mise_install_f=$(cd $(dirname $0) && pwd -P)/mise-install-f-if-missing.sh

echo ""
echo "mise up"
echo ""

$run_in_container \
  "--mount type=bind,src=$HOME/.dotfiles/config/mise/,dst=/mise \
  --env MISE_GLOBAL_CONFIG_FILE=/mise/mise.toml \
  --workdir /mise" \
  "-lc" "mise up"

echo ""
echo "mise install -f if missing"
echo ""

$run_in_new_shell "$HOME/.dotfiles/config/mise" $mise_install_f

echo ""
echo "mise prune"
echo ""

$run_in_container \
  "--mount type=bind,src=$HOME/.dotfiles/config/mise/,dst=/mise \
  --env MISE_GLOBAL_CONFIG_FILE=/mise/mise.toml \
  --workdir /mise" \
  "-lc" "mise prune -y"

echo ""
echo "mise lock"
echo ""

$run_in_container \
  "--mount type=bind,src=$HOME/.dotfiles/config/mise/,dst=/mise \
  --env MISE_GLOBAL_CONFIG_FILE=/mise/mise.toml \
  --workdir /mise" \
  "-lc" "mise lock"

