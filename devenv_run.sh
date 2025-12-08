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
MISE_GLOBAL_CONFIG_FILE=${MISE_GLOBAL_CONFIG_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/mise/config.toml}
MISE_DATA_DIR=${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}

CARGO_HOME=${CARGO_HOME:-$HOME/.cargo}
RUSTUP_HOME=${RUSTUP_HOME:-$HOME/.rustup}
UV_HOME=${XDG_DATA_HOME:-$HOME/.local/share}/uv

podman run -it --rm --init\
  --env IN_CONTAINER=1\
  --mount type=bind,src=$HOME/.config/env/,dst=/root/.config/env,ro\
  --mount type=bind,src=$HOME/.bashrc,dst=/root/.bashrc,ro\
  --mount type=bind,src=${SSL_CERT_FILE},dst=/etc/ssl/certs/ca-certificates.crt,ro\
  --env MISE_GLOBAL_CONFIG_FILE="${MISE_GLOBAL_CONFIG_FILE}"\
  --env MISE_TRUSTED_CONFIG_PATHS="${MISE_TRUSTED_CONFIG_PATHS}:$(dirname $MISE_GLOBAL_CONFIG_FILE)"\
  --mount type=bind,src=$(dirname $MISE_GLOBAL_CONFIG_FILE),dst=$(dirname $MISE_GLOBAL_CONFIG_FILE),ro\
  --env MISE_DATA_DIR=${MISE_DATA_DIR}\
  --mount type=bind,src=${MISE_DATA_DIR},dst=${MISE_DATA_DIR},ro\
  --mount type=bind,src=${UV_HOME},dst=${UV_HOME},ro\
  --env CARGO_HOME=${CARGO_HOME}\
  --mount type=bind,src=${CARGO_HOME},dst=${CARGO_HOME},ro\
  --env RUSTUP_HOME=${RUSTUP_HOME}\
  --mount type=bind,src=${RUSTUP_HOME},dst=${RUSTUP_HOME},ro\
  --mount type=volume,src=claude-config,dst=/root/.config/claude\
  --mount type=volume,src=gemini-config,dst=/root/.gemini\
  --mount type=volume,src=codex-config,dst=/root/.codex\
  --mount type=bind,src=.,dst=$(pwd)\
  --workdir $(pwd)\
  devenv:${tag}
