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
  echo "nvim lazy / ts restore"
  echo ""
  ./scripts/homeenv/nvim-lazy-restore.sh
  echo ""
  echo "mise install"
  echo ""
  ./scripts/homeenv/mise-install.sh
  echo ""
  echo "moonbit install"
  echo ""
  ./scripts/homeenv/moonbit-install.sh
  echo ""
  echo "moonbit tools build"
  echo ""
  ./scripts/homeenv/moonbit-tools-build.sh
popd
