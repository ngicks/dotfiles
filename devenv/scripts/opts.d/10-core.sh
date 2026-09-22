#!/usr/bin/env bash

set -eCu

SSL_CERT_FILE=${SSL_CERT_FILE:-/etc/ssl/certs/ca-certificates.crt}

printf "%s\n" "--env IN_CONTAINER=1"
printf "%s\n" "--env TERM=${TERM}"
printf "%s\n" "--env CMDMAN_CMD_ID"

printf "%s\n" "--env SSL_CERT_FILE=${SSL_CERT_FILE}"
printf "%s\n" "--mount type=bind,src=${SSL_CERT_FILE},dst=/etc/ssl/certs/ca-certificates.crt,ro"

# A bind mount with a missing src fails the whole `podman run`; create it.
env_config_dir=${XDG_CONFIG_HOME:-$HOME/.config}/env
mkdir -p "${env_config_dir}"

printf "%s\n" "--mount type=bind,src=${env_config_dir},dst=/root/.config/env,ro"

# Fresh tmpfs regardless of image content: image-layer /tmp already broke
# once (nix store normalization made it 0555, killing conmon -t inside the
# container), and per-run scratch should not leak between instances anyway.
printf "%s\n" "--mount type=tmpfs,dst=/tmp,tmpfs-size=1g,tmpfs-mode=1777"
printf "%s\n" "--mount type=tmpfs,dst=/run,tmpfs-size=64m,tmpfs-mode=0755"

printf "%s\n" "--env XDG_RUNTIME_DIR=/run/user/1000/"
printf "%s\n" "--mount type=tmpfs,dst=/run/user/1000/,tmpfs-size=10m"

# --memory-swap equal to --memory gives the container no swap: exceeding the
# limit is an OOM kill rather than a slowdown. tmpfs pages (the /tmp mount
# above) are charged against the same limit.
printf "%s\n" "--memory 4g"
printf "%s\n" "--memory-swap 4g"
