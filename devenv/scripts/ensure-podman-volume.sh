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
  gh-config
  glab-config
)

for volume in "${volumes[@]}"; do
  ensure_podman_volume "${volume}"
done
