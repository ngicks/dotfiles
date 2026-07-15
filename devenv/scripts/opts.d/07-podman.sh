#!/usr/bin/env bash

set -eCu

if [[ "${DEVENV_PODMAN:-1}" != "1" ]]; then
  exit 0
fi

# No src = annonymous
printf "%s\n" "--mount type=volume,dst=/root/.local/share/containers/graphroot"

if [[ -e /dev/fuse ]]; then
  printf "%s\n" "--device /dev/fuse"
else
  echo "[WARNING]: podman-in-podman is enabled but /dev/fuse does not exist; fuse-overlayfs will not work (DEVENV_PODMAN=0 to silence)" >&2
fi

printf "%s\n" "--security-opt label=disable"

dist_dir=${DEVENV_PODMAN_DIST:-${XDG_DATA_HOME:-$HOME/.local/share}/podman-dist}
if [[ "${dist_dir}" != "0" ]]; then
  if [[ -d "${dist_dir}/current" ]]; then
    printf "%s\n" "--mount type=bind,src=${dist_dir},dst=/root/.local/share/podman-dist,ro"
    printf "%s\n" "--mount type=bind,src=${dist_dir}/current/etc/containers,dst=/root/.config/containers,ro"
    for variant in "${dist_dir}/current/etc/containers/__additional_podman-in-podman"/*; do
      [[ -f "${variant}" ]] || continue
      printf "%s\n" "--mount type=bind,src=${variant},dst=/root/.config/containers/$(basename "${variant}"),ro"
    done
  else
    echo "[WARNING]: ${dist_dir}/current does not exist (run podman-static-dist install on the host); podman is not wired into the container" >&2
  fi
fi

if [[ "${DEVENV_PODMAN_IMAGE_STORE:-1}" == "1" ]]; then
  graphroot=$(podman info --format '{{.Store.GraphRoot}}' 2>/dev/null || true)
  if [[ -n "${graphroot}" && -d "${graphroot}" ]]; then
    # Referenced as an additionalimagestores entry by the
    # __additional_podman-in-podman storage.conf variant.
    printf "%s\n" "--mount type=bind,src=${graphroot},dst=/root/.local/share/containers/host-graphroot,ro"
  elif [[ -n "${DEVENV_PODMAN_IMAGE_STORE:-}" ]]; then
    echo "[WARNING]: DEVENV_PODMAN_IMAGE_STORE=1 but host graphroot could not be resolved (podman info) or does not exist; host image store is not mounted" >&2
  fi
fi
