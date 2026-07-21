#!/usr/bin/env bash

set -eCu

repo_root=$(cd "$(dirname "$0")/../.." && pwd -P)

if [[ -n ${DEVENV_TAG:-} ]]; then
  tag=${DEVENV_TAG}
else
  tag=$(git -C "${repo_root}" describe --tags --abbrev=0)
  tag=${tag#v}
fi

image="localhost/devenv/nix-home-manager-env:${tag}"

echo "loading ${image}" >&2
exec nix run "${repo_root}/nix-craft#devenv-home-base.copyTo" -- \
  "containers-storage:${image}"
