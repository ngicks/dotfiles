#!/bin/env bash

set -e

tag=$(cat devenv_ver)

pushd ./config/mise/
  MISE_DATA_DIR=${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}
  podman container run -it --rm --init \
    --mount type=bind,src=.,dst=/root/.config/mise \
    --mount type=bind,src=${MISE_DATA_DIR},dst=/root/.local/share/mise \
    localhost/devenv/devenv:${tag} \
    -lc "mise up"
  mise lock
popd
