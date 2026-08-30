#!/usr/bin/env bash

set -eCu

# A bind mount with a missing src fails the whole `podman run`; create it.
crabswarm_runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/crabswarm"
mkdir -p "${crabswarm_runtime_dir}"

# dst is pinned to /run/user/1000/ (the container's XDG_RUNTIME_DIR set in
# 10-core.sh), not the host path. ro still allows connecting to sockets inside.
printf "%s\n" "--mount type=bind,src=${crabswarm_runtime_dir},dst=/run/user/1000/crabswarm,ro"
