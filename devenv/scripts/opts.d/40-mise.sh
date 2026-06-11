#!/usr/bin/env bash

set -eCu

ro() {
  if [[ "${DEVENV_READONLY:-}" == "1" ]]; then
    printf ",ro"
  fi
}

MISE_CONFIG_DIR=$HOME/.dotfiles/config/mise
MISE_DATA_DIR=${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}

printf "%s\n" "--env MISE_GLOBAL_CONFIG_FILE=/root/.config/mise/mise.toml"
printf "%s\n" "--mount type=bind,src=${MISE_CONFIG_DIR},dst=/root/.config/mise,ro"
printf "%s\n" "--env MISE_DATA_DIR=${MISE_DATA_DIR}"
printf "%s\n" "--mount type=bind,src=${MISE_DATA_DIR},dst=${MISE_DATA_DIR}$(ro)"
