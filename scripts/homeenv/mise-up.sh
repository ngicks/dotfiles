#!/usr/bin/env bash

set -euo pipefail

run_in_container=$(cd $(dirname $0)/../../ && pwd -P)/devenv/scripts/run-devenv.sh

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

$run_in_container \
  "--mount type=bind,src=$HOME/.dotfiles/config/mise/,dst=/mise \
  --mount type=bind,src=$mise_install_f,dst=/mise-install-f-if-missing.sh,ro \
  --env MISE_GLOBAL_CONFIG_FILE=/mise/mise.toml \
  --workdir /mise" \
  "-lc" "/mise-install-f-if-missing.sh"

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

pushd "$HOME/.dotfiles/config/mise"
  mise lock $(mise ls --json | jq -r 'to_entries | map("\(.key)@\(.value[0].requested_version)") | join(" ")')
popd
