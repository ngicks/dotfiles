#!/bin/env bash

set -e

tag=$(git describe --tags --abbrev=0 | cut -c 2-)
runner=$(dirname $0)/run-devenv-wr.sh

pushd ./config/mise/
  # Let mise up be called in container
  # because it always tries to update things
  # under `~/.config/mise/`.
  runner \
    "--mount type=bind,src=$HOME/.dotfiles/config/mise/,dst=/root/.config/mise \
    --workdir /root/.config/mise" \
    "-lc" "mise up && mise lock"
popd

