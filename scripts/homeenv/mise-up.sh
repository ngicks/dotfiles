#!/usr/bin/env bash

runner=$(dirname $0)/../../devenv/scripts/run-devenv.sh

$runner \
  "--mount type=bind,src=$HOME/.dotfiles/config/mise/,dst=/mise \
  --env MISE_GLOBAL_CONFIG_FILE=/mise/mise.toml \
  --workdir /mise" \
  "-lc" "mise up && mise install -f 'go:*' || true && mise install -f 'pipx:*' || true && mise prune -y"

# Not sure, often it leaves old lock entries. split invocation.

pushd config/mise
  zsh -lc "mise lock"
popd
