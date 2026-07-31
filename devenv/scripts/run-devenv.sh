#!/usr/bin/env bash

set -eCu

script_dir=$(cd "$(dirname "$0")" && pwd -P)

image=$("${script_dir}/select-latest-devenv.sh")

container_opts=$("${script_dir}/opts.sh")

arg1=${1:-}
if [ "$#" -ge 1 ]; then
  shift
fi

# DEVENV_DRY_RUN=1 prints the assembled command instead of executing it. The
# podman volume is not ensured on this path, so the printed command may need a
# real run (or ensure-podman-volume.sh) first; opts.sh's mkdirs still happen.
if [[ "${DEVENV_DRY_RUN:-}" == "1" ]]; then
  printf "%s\n" "podman container run -it --rm --init ${container_opts//$'\n'/ } ${arg1} ${image} $*"
  exit 0
fi

"${script_dir}/ensure-podman-volume.sh"

podman container run -it --rm --init \
  ${container_opts} \
  ${arg1} \
  "${image}" \
  "$@"
