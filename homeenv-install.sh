#!/usr/bin/env bash

set -e

dir=$(dirname $0)

pushd $dir
  echo ""
  echo "system package manager update"
  echo ""
  ./scripts/homeenv/system-package-manager-update.sh
  echo ""
  echo "switch home manager"
  echo ""
  ./scripts/homeenv/nix-run-home-manager.sh
  echo ""
  echo "nvim plugin restore from lockfile"
  echo ""
  zsh -lc "./scripts/homeenv/nvim-pack-restore.sh"
  echo ""
  echo "mise install"
  echo ""
  zsh -lc "./scripts/homeenv/mise-install.sh"
popd
