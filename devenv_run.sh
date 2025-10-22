#!/bin/bash

set -Cue

tag=$(cat $(dirname $0)/devenv_ver)

if ! podman volume exists claude-config; then
  podman volume create claude-config
fi

if ! podman volume exists gemini-config; then
  podman volume create gemini-config
fi

if ! podman volume exists codex-config; then
  podman volume create codex-config
fi

SSL_CERT_FILE=${SSL_CERT_FILE:-/etc/ssl/certs/ca-certificates.crt}
MISE_DATA_DIR=${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}
UV_HOME=${XDG_DATA_HOME:-$HOME/.local/share}/uv

podman run -it --rm --init\
  --mount type=bind,src=$HOME/.config/env/,dst=/root/.config/env,ro\
  --mount type=bind,src=$HOME/.bashrc,dst=/root/.bashrc,ro\
  --mount type=bind,src=${SSL_CERT_FILE},dst=/etc/ssl/certs/ca-certificates.crt,ro\
  --mount type=bind,src=${MISE_DATA_DIR},dst=${MISE_DATA_DIR},ro\
  --env MISE_DATA_DIR=${MISE_DATA_DIR}\
  --env MISE_TRUSTED_CONFIG_PATHS="${MISE_TRUSTED_CONFIG_PATHS}:${MISE_DATA_DIR}"\
  --mount type=bind,src=${UV_HOME},dst=${UV_HOME},ro\
  --mount type=volume,src=claude-config,dst=/root/.config/claude\
  --mount type=volume,src=gemini-config,dst=/root/.gemini\
  --mount type=volume,src=codex-config,dst=/root/.codex\
  --mount type=bind,src=.,dst=$(pwd)\
  --workdir $(pwd)\
  devenv:${tag}
