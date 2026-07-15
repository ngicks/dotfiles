#!/usr/bin/env bash

set -eCu

script_dir=$(cd "$(dirname "$0")" && pwd -P)

image=$("${script_dir}/select-latest-devenv.sh")

"${script_dir}/ensure-podman-volume.sh"

container_opts=$("${script_dir}/opts.sh")

arg1=${1:-}
if [ "$#" -ge 1 ]; then
  shift
fi

podman container run -it --rm --init \
  ${container_opts} \
  ${arg1} \
  "${image}" \
  "$@"
