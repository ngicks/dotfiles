#!/usr/bin/env bash

runner=$(dirname $0)/../../devenv/scripts/run-devenv.sh
# Let mise up be called in container
# because it always tries to update things
# under `~/.config/mise/`.
$runner \
  "--mount type=bind,src=$HOME/.dotfiles/config/mise/,dst=/mise \
  --env MISE_GLOBAL_CONFIG_FILE=/mise/mise.toml \
  --workdir /mise" \
  "-lc" "mise up && mise prune -y && mise lock"

