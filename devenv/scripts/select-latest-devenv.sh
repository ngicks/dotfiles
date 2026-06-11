#!/usr/bin/env bash

set -eCu

script_dir=$(cd "$(dirname "$0")/.." && pwd -P)

image_repository="localhost/devenv/devenv"
if [ -n "${DEVENV_TAG:-""}" ]; then
  tag=${DEVENV_TAG}
else
  tag=$(git -C "${script_dir}" describe --tags --abbrev=0 | cut -c 2-)
fi

image=${image_repository}:${tag}
if ! podman image inspect "${image}" > /dev/null 2>&1; then
  echo "[WARNING]: ${image} not loaded" >&2
  echo "[WARNING]: Falling back to other tag" >&2
  fallback=$(podman image ls --format '{{.Repository}}:{{.Tag}}' --filter reference=${image_repository} | head -n 1)
  if [[ -z $fallback ]]; then
    echo "[ERROR]: no tag found" >&2
    exit 1
  fi
  image=$fallback
  echo "[WARNING]: Fall back image selected: ${image}" >&2
fi

printf "%s\n" "${image}"
