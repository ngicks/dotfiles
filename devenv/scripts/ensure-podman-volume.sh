#!/usr/bin/env bash

set -eCu

ensure_podman_volume() {
  local name=$1

  if ! podman volume exists "${name}"; then
    podman volume create "${name}"
  fi
}

volumes=(
  local-bin
  claude-bin
  claude-config
  gemini-config
  codex-config
  apm-config
  hf-token
  gh-config
  glab-config
)

for volume in "${volumes[@]}"; do
  ensure_podman_volume "${volume}"
done

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
