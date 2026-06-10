#!/usr/bin/env bash

set -eCu

image_repository="localhost/devenv/devenv"
if [ -n "${DEVENV_TAG:-""}" ]; then
  tag=${DEVENV_TAG}
else
  tag=$(git -C $(dirname $0) describe --tags --abbrev=0 | cut -c 2-)
fi

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
NVIM_CONFIG_DIR=$HOME/.dotfiles/config/nvim

MISE_CONFIG_DIR=$HOME/.dotfiles/config/mise
MISE_DATA_DIR=${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}
MISE_CONFIG_DIR=$HOME/.dotfiles/config/mise

CARGO_HOME=${CARGO_HOME:-$HOME/.cargo}

DENO_DIR=${DENO_DIR:-$HOME/.cache/deno}
DENO_INSTALL_ROOT=${DENO_INSTALL_ROOT:-$HOME/.deno/bin}

UV_HOME=${XDG_DATA_HOME:-$HOME/.local/share}/uv

NPM_CONFIG_USERCONFIG=${XDG_CONFIG_HOME:-$HOME/.config}/npm/npmrc
NPM_CONFIG_CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/npm

# The whole gitrepo tree is mounted into the container at its host path so that
# the pnpm content-addressable store (kept under __global_storage) and every
# project living under gitrepo share a single mount. pnpm hardlinks packages
# from the store into node_modules, and hardlinks only work within one
# filesystem -- one bind mount of gitrepo keeps the store and the projects on
# the same mount so hardlinking (rather than copying) works.
GITREPO_ROOT=${GITREPO_ROOT:-$HOME/gitrepo}
PNPM_CONFIG_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/pnpm

# Resolve the shared store from the host's pnpm (its store-dir is configured in
# the loginscript env). `pnpm store path` prints the versioned dir
# (.../store/v11); the store-dir handed to the container is its parent so the
# container's own pnpm appends its store-layout version. Fall back to the
# well-known path when pnpm is not on PATH (e.g. during `mise up`).
if pnpm_store_path=$(pnpm store path 2>/dev/null) && [ -n "${pnpm_store_path}" ]; then
  PNPM_STORE_DIR=${pnpm_store_path%/*}
else
  PNPM_STORE_DIR=${GITREPO_ROOT}/__global_storage/pnpm/store
fi

mkdir -p "${GITREPO_ROOT}" "${PNPM_STORE_DIR}" "${PNPM_CONFIG_DIR}"

timezone_opts=""
if [ -n "${TZ:-}" ]; then
  timezone_opts="${timezone_opts} --env TZ=${TZ}"
fi
if [ -f /etc/localtime ]; then
  timezone_opts="${timezone_opts} --mount type=bind,src=/etc/localtime,dst=/etc/localtime,ro"
fi

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
  ${timezone_opts}\
  \
  --mount type=bind,src=${XDG_CONFIG_HOME:-$HOME/.config}/env,dst=/root/.config/env,ro\
  \
  --env XDG_RUNTIME_DIR=/run/user/1000/\
  --mount type=tmpfs,dst=/run/user/1000/,tmpfs-size=10m\
  \
  --mount type=bind,src=${GITREPO_ROOT},dst=${GITREPO_ROOT}\
  \
  --mount type=bind,src=${NVIM_CONFIG_DIR},dst=/root/.config/nvim,ro\
  --mount type=bind,src=${NVIM_STD_DATA},dst=/root/.local/share/nvim,ro\
  --mount type=bind,src=${NVIM_STD_DATA},dst=${NVIM_STD_DATA},ro\
  \
  --env MISE_GLOBAL_CONFIG_FILE=/root/.config/mise/mise.toml \
  --mount type=bind,src=${MISE_CONFIG_DIR},dst=/root/.config/mise,ro\
  --env MISE_DATA_DIR=${MISE_DATA_DIR}\
  --mount type=bind,src=${MISE_DATA_DIR},dst=${MISE_DATA_DIR}$(ro)\
  \
  --env DENO_DIR=${DENO_DIR}\
  --mount type=bind,src=${DENO_DIR},dst=${DENO_DIR}\
  --env DENO_INSTALL_ROOT=${DENO_INSTALL_ROOT}\
  --mount type=bind,src=${DENO_INSTALL_ROOT},dst=${DENO_INSTALL_ROOT}\
  \
  --env UV_HOME=${UV_HOME}\
  --mount type=bind,src=${UV_HOME},dst=${UV_HOME}$(ro)\
  \
  --env CARGO_HOME=${CARGO_HOME}\
  --mount type=bind,src=${CARGO_HOME},dst=${CARGO_HOME}$(ro)\
  \
  --env NPM_CONFIG_USERCONFIG=${NPM_CONFIG_USERCONFIG}\
  --mount type=bind,src=${NPM_CONFIG_USERCONFIG},dst=${NPM_CONFIG_USERCONFIG}$(ro)\
  --env NPM_CONFIG_CACHE=${NPM_CONFIG_CACHE}\
  --mount type=bind,src=${NPM_CONFIG_CACHE},dst=${NPM_CONFIG_CACHE}\
  \
  --env pnpm_config_store_dir=${PNPM_STORE_DIR}\
  --mount type=bind,src=${PNPM_CONFIG_DIR},dst=/root/.config/pnpm,ro\
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
