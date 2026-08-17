#!/usr/bin/env bash

set -eCu

if [[ "${DEVENV_GPU:-}" != "1" ]]; then
  exit 0
fi

# CDI only: nvidia-container-toolkit (`nvidia-ctk cdi generate`) writes a
# spec that maps the devices plus the matching driver libs and binaries into
# the container. It also covers WSL2 (/dev/dxg-backed) hosts with the toolkit
# installed, so no raw-device fallback is provided.
if grep -qs "nvidia.com" /etc/cdi/*.yaml /etc/cdi/*.json /run/cdi/*.yaml /run/cdi/*.json 2>/dev/null; then
  printf "%s\n" "--device nvidia.com/gpu=all"
  exit 0
fi

# Unlike 05-kvm.sh there is no exit-1 branch: a stale .gpu.env on a GPU-less
# host must not brick every devenv launch.
echo "[WARNING]: DEVENV_GPU=1 but no nvidia CDI spec was found; GPU is not forwarded. Install nvidia-container-toolkit and run 'nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml'" >&2
exit 0
