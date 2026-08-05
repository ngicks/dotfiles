#!/usr/bin/env bash

# Rootless smoke test: run nvidia-smi inside a CUDA base container.
# Run as your normal user, NOT sudo.

set -e

if [ "$(id -u)" -eq 0 ]; then
  echo "run as your normal user (this verifies the rootless path)" >&2
  exit 1
fi

image=docker.io/nvidia/cuda:12.6.2-base-ubuntu24.04

exec podman run --rm --device nvidia.com/gpu=all "$image" nvidia-smi -L
