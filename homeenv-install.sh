#!/usr/bin/env bash

set -e

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

pushd "$dir"
  echo ""
  echo "system prerequisites"
  echo ""
  ./scripts/homeenv/system-prerequisites.sh
  echo ""
  echo "system package manager update"
  echo ""
  ./scripts/homeenv/system-package-manager-update.sh
  echo ""
  echo "switch home manager"
  echo ""
  ./scripts/homeenv/nix-run-home-manager.sh

  # The steps below install toolchains that honor GOPATH, CARGO_HOME,
  # RUSTUP_HOME, DENO_DIR and similar. Those come from the loginscript env
  # the switch above just linked, which this shell has not sourced. Running
  # on without them would populate the tools' default cache dirs (~/go,
  # ~/.cargo, ...) instead of the XDG layout, so stop here on a fresh install
  # and let a new shell pick the env up.
  if [ -z "${RUSTUP_HOME:-}" ] || [ -z "${GOPATH:-}" ]; then
    echo ""
    echo "=================================================================="
    echo " home-manager is switched, but this shell predates it and lacks"
    echo " the toolchain env (GOPATH, CARGO_HOME, RUSTUP_HOME, ...)."
    echo " Restart your shell (or open a new terminal), then re-execute:"
    echo ""
    echo "   ./homeenv-install.sh"
    echo ""
    echo "=================================================================="
    exit 1
  fi

  echo ""
  echo "moonbit install"
  echo ""
  ./scripts/homeenv/moonbit-install.sh

  echo ""
  echo "mise install"
  echo ""
  ./scripts/homeenv/mise-install.sh

  echo ""
  echo "generate shell completions"
  echo ""
  ./scripts/homeenv/generate-completions.sh

  echo ""
  echo "nvim plugin restore from lockfile"
  echo ""
  ./scripts/homeenv/nvim-pack-restore.sh
popd
