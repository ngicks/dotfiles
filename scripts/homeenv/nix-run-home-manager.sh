#!/usr/bin/env bash

set -e

# Resolve the repository root from this file's location so the script works
# from any working directory (and from the homeenv-*.sh wrappers).
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

cd "$repo_root/nix-craft"
nix run .#home-manager --extra-experimental-features "nix-command flakes" -- switch -b backup --flake .#default --impure --extra-experimental-features "nix-command flakes"

rm -f "${HOME}/.zcompdump"*

# The switch may have replaced the zsh startup files and the loginscript
# symlinks; recompile so no stale .zwc shadows the new generation.
"$repo_root/scripts/homeenv/zsh-compile-rc.sh"

# may need refresh

# nix run .#home-manager --refresh --extra-experimental-features "nix-command flakes" -- switch -b backup --flake .#default --impure --extra-experimental-features "nix-command flakes"

# nix-collect-garbage --delete-older-than 7d
