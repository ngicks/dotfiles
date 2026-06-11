#!/usr/bin/env bash

set -eCu

SSL_CERT_FILE=${SSL_CERT_FILE:-/etc/ssl/certs/ca-certificates.crt}

printf "%s\n" "--env IN_CONTAINER=1"
printf "%s\n" "--env TERM=${TERM}"

printf "%s\n" "--env SSL_CERT_FILE=${SSL_CERT_FILE}"
printf "%s\n" "--mount type=bind,src=${SSL_CERT_FILE},dst=/etc/ssl/certs/ca-certificates.crt,ro"

printf "%s\n" "--mount type=bind,src=${XDG_CONFIG_HOME:-$HOME/.config}/env,dst=/root/.config/env,ro"

printf "%s\n" "--env XDG_RUNTIME_DIR=/run/user/1000/"
printf "%s\n" "--mount type=tmpfs,dst=/run/user/1000/,tmpfs-size=10m"
