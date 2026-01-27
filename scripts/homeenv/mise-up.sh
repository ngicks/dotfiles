#!/bin/env bash

tag=$(git describe --tags --abbrev=0 | cut -c 2-)

runner=$(dirname $0)/run-devenv.sh
# Let mise up be called in container
# because it always tries to update things
# under `~/.config/mise/`.
$runner \
  "--mount type=bind,src=$HOME/.dotfiles/config/mise/,dst=/mise \
  --env MISE_GLOBAL_CONFIG_FILE=/mise/mise.toml \
  --workdir /mise" \
  "-lc" "mise up && mise lock"

