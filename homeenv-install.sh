#!/bin/env bash

set -e

dir=$(dirname $0)

pushd $dir
  ./scripts/homeenv/system-package-manager-update.sh
  ./scripts/homeenv/mise-install.sh
  ./scripts/homeenv/nvim-lazy-restore.sh
  ./scripts/homeenv/nix-run-home-manager.sh
popd
