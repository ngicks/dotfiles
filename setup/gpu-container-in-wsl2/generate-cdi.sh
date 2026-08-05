#!/usr/bin/env bash

# Generates the CDI spec at /etc/cdi/nvidia.yaml (nvidia-ctk auto-detects
# WSL2). Run with sudo. Rerun after Windows driver updates or wsl --update.

set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "run with sudo" >&2
  exit 1
fi

mkdir -p /etc/cdi
nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
chmod 0644 /etc/cdi/nvidia.yaml

echo
echo "available CDI devices:"
nvidia-ctk cdi list
