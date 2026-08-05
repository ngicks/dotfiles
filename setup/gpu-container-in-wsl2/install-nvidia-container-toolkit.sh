#!/usr/bin/env bash

# Installs nvidia-container-toolkit from NVIDIA's apt repository.
# Run with sudo. Idempotent.

set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "run with sudo" >&2
  exit 1
fi

if ! command -v apt-get &> /dev/null; then
  echo "only apt-based distros are scripted; follow NVIDIA's install guide manually:" >&2
  echo "https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html" >&2
  exit 1
fi

keyring=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
list=/etc/apt/sources.list.d/nvidia-container-toolkit.list

if [ ! -f "$keyring" ]; then
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
    | gpg --dearmor -o "$keyring"
fi

curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed "s#deb https://#deb [signed-by=${keyring}] https://#g" \
  > "$list"

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nvidia-container-toolkit

nvidia-ctk --version
