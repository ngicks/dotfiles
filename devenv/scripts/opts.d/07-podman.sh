#!/usr/bin/env bash

set -eCu

# Mount the host podman-static dist and image store into the container so the
# in-container podman reuses host binaries and images. Opt in with DEVENV_PODMAN=1.
PODMAN_DIST_DIR=${XDG_DATA_HOME:-$HOME/.local/share}/podman
PODMAN_GRAPHROOT_DIR=${XDG_DATA_HOME:-$HOME/.local/share}/containers/graphroot
PODMAN_STATIC_DIST_BIN=${XDG_CACHE_HOME:-$HOME/.cache}/devenv/podman-static-dist/podman-static-dist

if [[ "${DEVENV_PODMAN:-}" != "1" ]]; then
  exit 0
fi

if [[ ! -d "${PODMAN_DIST_DIR}" ]]; then
  echo "[WARNING]: DEVENV_PODMAN=1 but ${PODMAN_DIST_DIR} does not exist; podman dist and image store are not mounted" >&2
  exit 0
fi

if [[ ! -d "${PODMAN_GRAPHROOT_DIR}" ]]; then
  echo "[WARNING]: DEVENV_PODMAN=1 but ${PODMAN_GRAPHROOT_DIR} does not exist; podman dist and image store are not mounted" >&2
  exit 0
fi

if [[ ! -f "${PODMAN_STATIC_DIST_BIN}" ]]; then
  echo "[WARNING]: DEVENV_PODMAN=1 but ${PODMAN_STATIC_DIST_BIN} does not exist; run ensure-podman-static-dist.sh to build it; podman is not wired" >&2
  exit 0
fi

# Host dist (binaries + etc), read-only.
printf "%s\n" "--mount type=bind,src=${PODMAN_DIST_DIR},dst=/root/.local/share/podman,ro"
# Host image store, wired in as an additional (read-only) image store.
printf "%s\n" "--mount type=bind,src=${PODMAN_GRAPHROOT_DIR},dst=/root/.local/share/containers/host-graphroot,ro"
# Anonymous, per-run writable inner graphroot (auto-removed by --rm); overlay-on-overlay is rejected.
printf "%s\n" "--mount type=volume,dst=/root/.local/share/containers/graphroot"
# fuse-overlayfs needs /dev/fuse.
printf "%s\n" "--device /dev/fuse"
# The in-container wiring CLI.
printf "%s\n" "--mount type=bind,src=${PODMAN_STATIC_DIST_BIN},dst=/usr/local/bin/podman-static-dist,ro"
printf "%s\n" "--env DEVENV_PODMAN=1"
# Wire the host image store in at runtime via containers-storage's STORAGE_OPTS,
# instead of injecting it into the materialized storage.conf. STORAGE_OPTS is
# comma-split and REPLACES all overlay graph-driver options from storage.conf,
# so mount_program (fuse-overlayfs) and ignore_chown_errors are re-specified
# alongside the host image store. NOTE: storage.conf's mountopt="nodev,fsync=0"
# cannot ride along — its value contains a comma, which STORAGE_OPTS would split
# into a bogus option; the container falls back to fuse-overlayfs mount defaults.
printf "%s\n" "--env STORAGE_OPTS=overlay.mount_program=/root/.local/containers/bin/fuse-overlayfs,overlay.ignore_chown_errors=true,overlay.imagestore=/root/.local/share/containers/host-graphroot"
