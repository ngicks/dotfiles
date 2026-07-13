#!/usr/bin/env bash

set -eCu

ro() {
  if [[ "${DEVENV_READONLY:-}" == "1" ]]; then
    printf ",ro"
  fi
}

GITREPO_ROOT=${GITREPO_ROOT:-$HOME/gitrepo}
PNPM_CONFIG_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/pnpm
NPM_CONFIG_USERCONFIG=${XDG_CONFIG_HOME:-$HOME/.config}/npm/npmrc
NPM_CONFIG_CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/npm

# Resolve the shared store from the host's pnpm (its store-dir is configured in
# the loginscript env). `pnpm store path` prints the versioned dir
# (.../store/v11); the store-dir handed to the container is its parent so the
# container's own pnpm appends its store-layout version. Fall back to the
# well-known path when pnpm is not on PATH (e.g. during `mise up`).
if pnpm_store_path=$(pnpm store path 2>/dev/null) && [ -n "${pnpm_store_path}" ]; then
  PNPM_STORE_DIR=${pnpm_store_path%/*}
else
  PNPM_STORE_DIR=${GITREPO_ROOT}/__global_storage/pnpm/store
fi

mkdir -p "${PNPM_STORE_DIR}" "${PNPM_CONFIG_DIR}" "${NPM_CONFIG_CACHE}" "${NPM_CONFIG_USERCONFIG%/*}"
# npmrc is bind-mounted as a file; a missing src fails the whole `podman run`.
[ -f "${NPM_CONFIG_USERCONFIG}" ] || : > "${NPM_CONFIG_USERCONFIG}"

printf "%s\n" "--env NPM_CONFIG_USERCONFIG=${NPM_CONFIG_USERCONFIG}"
printf "%s\n" "--mount type=bind,src=${NPM_CONFIG_USERCONFIG},dst=${NPM_CONFIG_USERCONFIG}$(ro)"
printf "%s\n" "--env NPM_CONFIG_CACHE=${NPM_CONFIG_CACHE}"
printf "%s\n" "--mount type=bind,src=${NPM_CONFIG_CACHE},dst=${NPM_CONFIG_CACHE}"

printf "%s\n" "--env pnpm_config_store_dir=${PNPM_STORE_DIR}"
printf "%s\n" "--mount type=bind,src=${PNPM_CONFIG_DIR},dst=/root/.config/pnpm,ro"
