#!/bin/env bash

set -e

dir=$(dirname $0)

pushd $dir
  ./scripts/homeenv/system-package-manager-update.sh
  ./scripts/homeenv/mise-up.sh
  ./scripts/homeenv/nvim-lazy-sync.sh
  pushd ./nix-craft/
    nix flake update
  popd
  ./scripts/homeenv/nix-run-home-manager.sh
popd
