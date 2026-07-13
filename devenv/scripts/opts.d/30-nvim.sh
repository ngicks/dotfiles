#!/usr/bin/env bash

set -eCu

NVIM_STD_DATA=${XDG_DATA_HOME:-$HOME/.local/share}/nvim
NVIM_CONFIG_DIR=$HOME/.dotfiles/config/nvim

# A bind mount with a missing src fails the whole `podman run`; create it.
mkdir -p "${NVIM_STD_DATA}"

printf "%s\n" "--mount type=bind,src=${NVIM_CONFIG_DIR},dst=/root/.config/nvim,ro"
printf "%s\n" "--mount type=bind,src=${NVIM_STD_DATA},dst=/root/.local/share/nvim,ro"
printf "%s\n" "--mount type=bind,src=${NVIM_STD_DATA},dst=${NVIM_STD_DATA},ro"
