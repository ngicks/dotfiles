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
mise_data_dir=${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}

podman run -it --rm --init\
  --mount type=bind,src=$HOME/.config/env/,dst=/root/.config/env,ro\
  --mount type=bind,src=$HOME/.bashrc,dst=/root/.bashrc,ro\
  --mount type=bind,src=${SSL_CERT_FILE},dst=/etc/ssl/certs/ca-certificates.crt,ro\
  --mount type=bind,src=${mise_data_dir},dst=/root/.local/share/mise,ro\
  --mount type=volume,src=claude-config,dst=/root/.config/claude\
  --mount type=volume,src=gemini-config,dst=/root/.gemini\
  --mount type=volume,src=codex-config,dst=/root/.codex\
  --mount type=bind,src=.,dst=$(pwd)\
  --workdir $(pwd)\
  devenv:${tag}
