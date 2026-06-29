#!/usr/bin/env bash

set -eCu

# Forward the host incus daemon socket and client config into the container so
# the in-container `incus` CLI drives the host incusd. Opt in with DEVENV_INCUS=1.
INCUS_SOCKET=${INCUS_SOCKET:-${INCUS_DIR:-/var/lib/incus}/unix.socket}
INCUS_CONFIG_DIR=${INCUS_CONF:-${XDG_CONFIG_HOME:-$HOME/.config}/incus}

if [[ "${DEVENV_INCUS:-}" != "1" ]]; then
  exit 0
fi

if [[ ! -S "${INCUS_SOCKET}" ]]; then
  echo "[WARNING]: DEVENV_INCUS=1 but ${INCUS_SOCKET} is not a socket; incus socket and config are not mounted" >&2
  exit 0
fi

mkdir -p "${INCUS_CONFIG_DIR}"

# Forward the unix domain socket as-is (same path inside the container).
printf "%s\n" "--mount type=bind,src=${INCUS_SOCKET},dst=${INCUS_SOCKET}"
printf "%s\n" "--mount type=bind,src=${INCUS_CONFIG_DIR},dst=/root/.config/incus"
