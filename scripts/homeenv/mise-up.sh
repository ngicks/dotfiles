#!/usr/bin/env bash

set -uo pipefail

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

# -g: MISE_GLOBAL_CONFIG_FILE makes /mise/mise.toml the global config, and
# without -g mise scopes to the project config root and finds no tools to
# lock. No tool args: mise lock resolves every requested version from the
# config itself; listing installed versions via mise ls picked the stale
# inactive install when two versions of a tool were present.
$run_in_container \
  "--mount type=bind,src=$HOME/.dotfiles/config/mise/,dst=/mise \
  --env MISE_GLOBAL_CONFIG_FILE=/mise/mise.toml \
  --workdir /mise" \
  "-lc" "mise lock -g"
