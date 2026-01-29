#!/usr/bin/env bash

set -e

dir=$(dirname $0)

pushd $dir
  echo ""
  echo "system package manager update"
  echo ""
  ./scripts/homeenv/system-package-manager-update.sh
  echo ""
  echo "mise up"
  echo ""
  ./scripts/homeenv/mise-up.sh
  echo ""
  echo "nvim lazy / ts update"
  echo ""
  ./scripts/homeenv/nvim-lazy-sync.sh
  echo ""
  echo "nix flake update"
  echo ""
  pushd ./nix-craft/
    nix flake update
  popd
popd
