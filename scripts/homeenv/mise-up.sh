#!/bin/env bash

set -e

tag=$(git describe --tags --abbrev=0 | cut -c 2-)

pushd ./config/mise/
  # Let mise up be called in container
  # because it always tries to update things
  # under `~/.config/mise/`.
  MISE_DATA_DIR=${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}
  podman container run -it --rm --init \
    --mount type=bind,src=.,dst=/root/.config/mise \
    --mount type=bind,src=${MISE_DATA_DIR},dst=/root/.local/share/mise \
    localhost/devenv/devenv:${tag} \
    -lc "mise up"
  mise lock
popd
