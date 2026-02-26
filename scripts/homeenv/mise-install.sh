#!/usr/bin/env bash

set -e

pushd ./config/mise/
  # it always fails because of read-only lock file
  mise install || true
  mise prune -y || true
popd

runner=$(dirname $0)/../../devenv/scripts/run-devenv.sh
# Let mise up be called in container
# because it always tries to update things
# under `~/.config/mise/`.
$runner \
  "--workdir /" \
  "-lc" "mise install || true && mise prune -y || true"

