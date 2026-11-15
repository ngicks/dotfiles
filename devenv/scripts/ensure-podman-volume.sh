#!/usr/bin/env bash

set -eCu

# codex offers no way to relocate <CODEX_HOME>/logs_2.sqlite, so route it into
# the tmpfs that 90-volumes.sh mounts at logs-ram. The plain dir keeps the
# link resolvable (on disk) in containers started without that mount.
codex_mp=$(podman volume inspect codex-config --format '{{.Mountpoint}}')
if [ ! -L "${codex_mp}/logs_2.sqlite" ]; then
  podman unshare sh -c '
    mkdir -p "$1/logs-ram"
    rm -f "$1"/logs_2.sqlite "$1"/logs_2.sqlite-wal "$1"/logs_2.sqlite-shm
    ln -sfn logs-ram/logs_2.sqlite "$1/logs_2.sqlite"
  ' _ "${codex_mp}"
fi

# 90-volumes.sh mounts config/ and local/ of apm-config as subpaths, which
# podman requires to exist. The volume used to be mounted whole at ~/.apm, so
# anything else at its top level is that old content and belongs in config/.
apm_mp=$(podman volume inspect apm-config --format '{{.Mountpoint}}')
if [ ! -d "${apm_mp}/config" ] || [ ! -d "${apm_mp}/local" ]; then
  podman unshare sh -c '
    mkdir -p "$1/config" "$1/local"
    for entry in "$1"/* "$1"/.[!.]*; do
      [ -e "${entry}" ] || [ -L "${entry}" ] || continue
      case "${entry##*/}" in
        config | local) ;;
        *) mv "${entry}" "$1/config/" ;;
      esac
    done
  ' _ "${apm_mp}"
fi
