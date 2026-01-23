#!/bin/env bash

set -eCu

image_repository="localhost/devenv/devenv"
tag=$(git -C $(dirname $0) describe --tags --abbrev=0 | cut -c 2-)

image=${image_repository}:${tag}
if ! podman image inspect ${image} > /dev/null 2>&1; then
  echo "[WARNING]: ${image} not loaded"
  echo "[WARNING]: Falling back to other tag"
  fallback=$(podman image ls --format '{{.Repository}}:{{.Tag}}' --filter reference=${image_repository} | head -n 1)
  if [[ -z $fallback ]]; then
    echo "[ERROR]: no tag found"
    exit 1
  fi
  image=$fallback
  echo "[WARNING]: Fall back image selected: ${image}"
fi


if ! podman volume exists local-bin; then
  podman volume create local-bin
fi

if ! podman volume exists claude-bin; then
  podman volume create claude-bin
fi

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

MISE_CONFIG_DIR=$HOME/.dotfiles/config/mise
MISE_DATA_DIR=${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}
MISE_CONFIG_DIR=$HOME/.dotfiles/config/mise

CARGO_HOME=${CARGO_HOME:-$HOME/.cargo}
RUSTUP_HOME=${RUSTUP_HOME:-$HOME/.rustup}

UV_HOME=${XDG_DATA_HOME:-$HOME/.local/share}/uv

NPM_CONFIG_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/npm
NPM_CONFIG_GLOBALCONFIG=${NPM_CONFIG_DIR}/npmrc
NPM_CACHE_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/npm

if_ro() {
  if [[ "${DEVENV_READONLY:-}" == "1" ]]; then
    printf "%s" "$1"
    return
  fi
  printf "%s" "$2"
}

ro() {
  if_ro ",ro" ""
}

arg1="$1"
shift

podman container run -it --rm --init \
  \
  --env IN_CONTAINER=1\
  --env TERM=${TERM}\
  \
  --env SSL_CERT_FILE=${SSL_CERT_FILE}\
  --mount type=bind,src=${SSL_CERT_FILE},dst=/etc/ssl/certs/ca-certificates.crt,ro\
  \
  --mount type=bind,src=${XDG_CONFIG_HOME:-$HOME/.config}/env,dst=/root/.config/env,ro\
  \
  --mount type=bind,src=${NVIM_STD_DATA},dst=/root/.local/share/nvim,ro\
  \
  --env MISE_GLOBAL_CONFIG_FILE=/root/.config/mise_host/mise.toml \
  --mount type=bind,src=${MISE_CONFIG_DIR},dst=/root/.config/mise_host,ro\
  --env MISE_DATA_DIR=${MISE_DATA_DIR}\
  --mount type=bind,src=${MISE_DATA_DIR},dst=${MISE_DATA_DIR}$(ro)\
  \
  --env UV_HOME=${UV_HOME}\
  --mount type=bind,src=${UV_HOME},dst=${UV_HOME}$(ro)\
  \
  --env CARGO_HOME=${CARGO_HOME}\
  --mount type=bind,src=${CARGO_HOME},dst=${CARGO_HOME}$(ro)\
  --env RUSTUP_HOME=${RUSTUP_HOME}\
  --mount type=bind,src=${RUSTUP_HOME},dst=${RUSTUP_HOME}$(ro)\
  \
  --env NPM_CONFIG_GLOBALCONFIG=${NPM_CONFIG_GLOBALCONFIG}\
  --mount type=bind,src=${NPM_CONFIG_DIR},dst=${NPM_CONFIG_DIR}$(ro)\
  --mount type=bind,src=${NPM_CACHE_DIR},dst=${NPM_CACHE_DIR}\
  \
  --env GOBIN=${GOBIN}\
  --env GOPATH=${GOPATH}\
  --mount type=bind,src=${GOPATH},dst=${GOPATH}\
  \
  --mount type=volume,src=local-bin,dst=/root/.local/bin\
  --mount type=volume,src=claude-bin,dst=/root/.local/share/claude\
  --mount type=volume,src=claude-config,dst=/root/.config/claude\
  --mount type=volume,src=gemini-config,dst=/root/.gemini\
  --mount type=volume,src=codex-config,dst=/root/.codex\
  \
  ${arg1}\
  \
  ${image}\
  "$@"
