#!/usr/bin/env bash

set -eCu

if [[ "${DEVENV_PODMAN:-}" != "1" ]]; then
  exit 0
fi

if ! command -v go >/dev/null 2>&1; then
  echo "[WARNING]: DEVENV_PODMAN=1 but go is not on PATH; podman-static-dist is not built" >&2
  exit 0
fi

script_dir=$(cd "$(dirname "$0")" && pwd -P)
module_dir="${script_dir}/../../build/podman-static"

bin=${XDG_CACHE_HOME:-$HOME/.cache}/devenv/podman-static-dist/podman-static-dist

mkdir -p "$(dirname "${bin}")"

(cd "${module_dir}" && CGO_ENABLED=0 go build -o "${bin}" ./cmd/podman-static-dist)
