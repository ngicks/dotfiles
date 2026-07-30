#!/usr/bin/env bash

set -eCu

ro() {
  if [[ "${DEVENV_READONLY:-}" == "1" ]]; then
    printf ",ro"
  fi
}

GITREPO_ROOT=${GITREPO_ROOT:-$HOME/gitrepo}
CARGO_HOME=${CARGO_HOME:-$HOME/.cargo}
DENO_DIR=${DENO_DIR:-$HOME/.cache/deno}
DENO_INSTALL_ROOT=${DENO_INSTALL_ROOT:-$HOME/.deno/bin}
UV_HOME=${XDG_DATA_HOME:-$HOME/.local/share}/uv

# Resolve the shared cache from the host's uv (UV_CACHE_DIR is configured in
# the loginscript env). It lives under gitrepo, which 20-gitrepo.sh mounts at
# its host path, so no extra mount is needed and hardlinks into project venvs
# keep working. Fall back to the well-known path when uv is not on PATH.
if uv_cache_dir=$(uv cache dir 2>/dev/null) && [ -n "${uv_cache_dir}" ]; then
  UV_CACHE_DIR=${uv_cache_dir}
else
  UV_CACHE_DIR=${GITREPO_ROOT}/__global_storage/uv/cache
fi

# A bind mount with a missing src fails the whole `podman run`; these only
# appear once their runtime has been used, so create them.
mkdir -p "${CARGO_HOME}" "${DENO_DIR}" "${DENO_INSTALL_ROOT}" "${UV_HOME}"

printf "%s\n" "--env DENO_DIR=${DENO_DIR}"
printf "%s\n" "--mount type=bind,src=${DENO_DIR},dst=${DENO_DIR}"
printf "%s\n" "--env DENO_INSTALL_ROOT=${DENO_INSTALL_ROOT}"
printf "%s\n" "--mount type=bind,src=${DENO_INSTALL_ROOT},dst=${DENO_INSTALL_ROOT}"

printf "%s\n" "--env UV_HOME=${UV_HOME}"
printf "%s\n" "--mount type=bind,src=${UV_HOME},dst=${UV_HOME}$(ro)"
printf "%s\n" "--env UV_CACHE_DIR=${UV_CACHE_DIR}"

printf "%s\n" "--env CARGO_HOME=${CARGO_HOME}"
printf "%s\n" "--mount type=bind,src=${CARGO_HOME},dst=${CARGO_HOME}$(ro)"
