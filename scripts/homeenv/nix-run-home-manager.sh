#!/usr/bin/env bash

set -e

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
if [[ -d "$config_dir" ]]; then
  # `-xtype l` finds dangling symlink
  find "$config_dir" -xtype l -delete
fi

cd ./nix-craft/
nix run .#home-manager --extra-experimental-features "nix-command flakes" -- switch -b backup --flake .#default --impure --extra-experimental-features "nix-command flakes"

# may need refresh

# nix run .#home-manager --refresh --extra-experimental-features "nix-command flakes" -- switch -b backup --flake .#default --impure --extra-experimental-features "nix-command flakes"

# nix-collect-garbage --delete-older-than 7d
