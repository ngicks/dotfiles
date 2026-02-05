#!/usr/bin/env bash

set -euo pipefail

pushd $(dirname $0)

nix-shell --command ./build-in-env.sh

popd
