#!/usr/bin/env bash

set -e

cd ./nix-craft/
nix run .#home-manager --extra-experimental-features "nix-command flakes" -- switch -b backup --flake .#default --impure --extra-experimental-features "nix-command flakes"

# may need refresh

# nix run .#home-manager --refresh --extra-experimental-features "nix-command flakes" -- switch -b backup --flake .#default --impure --extra-experimental-features "nix-command flakes"

# nix-collect-garbage --delete-older-than 7d
