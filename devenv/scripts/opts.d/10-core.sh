#!/usr/bin/env bash

set -eCu

SSL_CERT_FILE=${SSL_CERT_FILE:-/etc/ssl/certs/ca-certificates.crt}

printf "%s\n" "--env IN_CONTAINER=1"
printf "%s\n" "--env TERM=${TERM}"
printf "%s\n" "--env CMDMAN_CMD_ID"

printf "%s\n" "--env SSL_CERT_FILE=${SSL_CERT_FILE}"
printf "%s\n" "--mount type=bind,src=${SSL_CERT_FILE},dst=/etc/ssl/certs/ca-certificates.crt,ro"

# A bind mount with a missing src fails the whole `podman run`; create it.
env_config_dir=${XDG_CONFIG_HOME:-$HOME/.config}/env
mkdir -p "${env_config_dir}"

printf "%s\n" "--mount type=bind,src=${env_config_dir},dst=/root/.config/env,ro"

# Fresh tmpfs regardless of image content: image-layer /tmp already broke
# once (nix store normalization made it 0555, killing conmon -t inside the
# container), and per-run scratch should not leak between instances anyway.
printf "%s\n" "--mount type=tmpfs,dst=/tmp,tmpfs-size=1g,tmpfs-mode=1777"
printf "%s\n" "--mount type=tmpfs,dst=/run,tmpfs-size=64m,tmpfs-mode=0755"

printf "%s\n" "--env XDG_RUNTIME_DIR=/run/user/1000/"
printf "%s\n" "--mount type=tmpfs,dst=/run/user/1000/,tmpfs-size=10m"

# Prints the total memory, in bytes, of the system that runs the containers.
container_host_mem_bytes() {
  # On Linux podman runs natively (WSL2 included: its VM is this kernel), so
  # /proc/meminfo is the container host and is cheap enough to read every run.
  if [[ -r /proc/meminfo ]]; then
    awk '/^MemTotal:/ { print $2 * 1024; exit }' /proc/meminfo
    return
  fi

  # Elsewhere (macOS) containers run inside the podman machine VM. Querying it
  # costs a round-trip into the VM, so the answer is cached for a day; a day
  # also bounds staleness after `podman machine set --memory`.
  local cache=${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/devenv/container-host-mem-bytes
  if [[ -s "${cache}" ]] && [[ -n "$(find "${cache}" -mmin -1440 2>/dev/null)" ]]; then
    cat "${cache}"
    return
  fi
  local mem
  mem=$(podman info --format '{{.Host.MemTotal}}' 2>/dev/null) || return 1
  mkdir -p "$(dirname "${cache}")"
  printf "%s\n" "${mem}" >|"${cache}"
  printf "%s\n" "${mem}"
}

# Each devenv container may use half of the container host's memory.
# --memory-swap equal to --memory gives the container no swap: exceeding the
# limit is an OOM kill rather than a slowdown. tmpfs pages (the /tmp mount
# above) are charged against the same limit.
mem_limit=4g
if host_mem=$(container_host_mem_bytes) && [[ "${host_mem}" =~ ^[0-9]+$ ]] && ((host_mem > 0)); then
  mem_limit="$((host_mem / 2 / 1024 / 1024))m"
else
  echo "[WARNING]: could not determine container host memory; falling back to --memory ${mem_limit}" >&2
fi
printf "%s\n" "--memory ${mem_limit}"
printf "%s\n" "--memory-swap ${mem_limit}"
