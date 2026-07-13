#!/usr/bin/env bash

set -eCu

SSL_CERT_FILE=${SSL_CERT_FILE:-/etc/ssl/certs/ca-certificates.crt}

printf "%s\n" "--env IN_CONTAINER=1"
printf "%s\n" "--env TERM=${TERM}"

printf "%s\n" "--env SSL_CERT_FILE=${SSL_CERT_FILE}"
printf "%s\n" "--mount type=bind,src=${SSL_CERT_FILE},dst=/etc/ssl/certs/ca-certificates.crt,ro"

# A bind mount with a missing src fails the whole `podman run`; create them.
env_config_dir=${XDG_CONFIG_HOME:-$HOME/.config}/env
os_image_dir=$HOME/blobs/os-image
mkdir -p "${env_config_dir}" "${os_image_dir}"

printf "%s\n" "--mount type=bind,src=${env_config_dir},dst=/root/.config/env,ro"
printf "%s\n" "--mount type=bind,src=${os_image_dir},dst=/root/blobs/os-image,ro"

printf "%s\n" "--env XDG_RUNTIME_DIR=/run/user/1000/"
printf "%s\n" "--mount type=tmpfs,dst=/run/user/1000/,tmpfs-size=10m"
