#!/usr/bin/env bash

set -eCu

host_proxy=${HTTP_PROXY:-${http_proxy:-}}

case "${host_proxy}" in
  http://127.0.0.1:3128|https://127.0.0.1:3128)
    ;;
  *)
    exit 0
    ;;
esac

DEVENV_PROXY=${DEVENV_PROXY:-http://host.containers.internal:3128}

printf "%s\n" "--env HTTP_PROXY=${DEVENV_PROXY}"
printf "%s\n" "--env HTTPS_PROXY=${DEVENV_PROXY}"
printf "%s\n" "--env http_proxy=${DEVENV_PROXY}"
printf "%s\n" "--env https_proxy=${DEVENV_PROXY}"

if [ -n "${NO_PROXY:-}" ]; then
  printf "%s\n" "--env NO_PROXY=${NO_PROXY}"
fi

if [ -n "${no_proxy:-}" ]; then
  printf "%s\n" "--env no_proxy=${no_proxy}"
fi
