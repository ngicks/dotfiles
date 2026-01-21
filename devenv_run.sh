#!/bin/env bash

set -Cue

tag="${$(git -C $(dirname $0) describe --tags --abbrev=0):1}"

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

NVIM_STD_DATA=${XDG_DATA_HOME:-$HOME/.local/share}/nvim
MISE_DATA_DIR=${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}
MISE_CONFIG_DIR=./config/mise
CARGO_HOME=${CARGO_HOME:-$HOME/.cargo}
RUSTUP_HOME=${RUSTUP_HOME:-$HOME/.rustup}
UV_HOME=${XDG_DATA_HOME:-$HOME/.local/share}/uv

podman run -it --rm --init\
  --env IN_CONTAINER=1\
  --env TERM=${TERM}\
  --env SSL_CERT_FILE=${SSL_CERT_FILE}\
  --mount type=bind,src=${SSL_CERT_FILE},dst=/etc/ssl/certs/ca-certificates.crt,ro\
  --mount type=bind,src=$HOME/.config/env/,dst=/root/.config/env,ro\
  --mount type=bind,src=${NVIM_STD_DATA},dst=/root/.local/share/nvim,ro\
  --env MISE_GLOBAL_CONFIG_FILE=/root/.config/mise_host/mise.toml \
  --mount type=bind,src=${MISE_CONFIG_DIR},dst=/root/.config/mise_host,ro\
  --mount type=bind,src=${MISE_DATA_DIR},dst=/root/.local/share/mise,ro\
  --mount type=bind,src=${UV_HOME},dst=/root/.local/share/uv,ro\
  --env CARGO_HOME=/root/.local/share/cargo\
  --mount type=bind,src=${CARGO_HOME},dst=/root/.local/share/cargo,ro\
  --env RUSTUP_HOME=/root/.local/share/rustup\
  --mount type=bind,src=${RUSTUP_HOME},dst=/root/.local/share/rustup,ro\
  --mount type=volume,src=claude-config,dst=/root/.config/claude\
  --mount type=volume,src=gemini-config,dst=/root/.gemini\
  --mount type=volume,src=codex-config,dst=/root/.codex\
  --mount type=bind,src=.,dst=$(pwd)\
  --workdir $(pwd)\
  localhost/devenv/devenv:${tag}
