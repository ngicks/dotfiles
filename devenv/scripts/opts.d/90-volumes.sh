#!/usr/bin/env bash

set -eCu

mount_volume() {
  local name=$1
  local destination=$2

  if [[ "${DEVENV_DRY_RUN:-}" != "1" ]]; then
    if ! podman volume exists "${name}"; then
      podman volume create "${name}" >&2
    fi
  fi

  printf "%s\n" "--mount type=volume,src=${name},dst=${destination}"
}

mount_volume local-bin /root/.local/bin
mount_volume claude-bin /root/.local/share/claude
mount_volume claude-config /root/.config/claude
mount_volume gemini-config /root/.gemini
mount_volume opencode-config /root/.config/opencode
mount_volume opencode-data /root/.local/share/opencode
mount_volume opencode-state /root/.local/state/opencode
mount_volume codex-config /root/.codex
# codex hardcodes <CODEX_HOME>/logs_2.sqlite and its WAL churn burns the
# SSD-backed volume; ensure-podman-volume.sh symlinks it under logs-ram.
printf "%s\n" "--mount type=tmpfs,dst=/root/.codex/logs-ram,tmpfs-size=512m"
mount_volume apm-config /root/.apm
mount_volume hf-token /root/.config/huggingface
mount_volume gh-config /root/.config/gh
mount_volume glab-config /root/.config/glab-cli
