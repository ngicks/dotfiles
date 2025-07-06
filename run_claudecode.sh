#!/bin/bash

if ! podman volume exists claude-config; then
  podman volume create claude-config
fi

podman run -it --rm --init\
  --mount type=volume,src=claude-config,dst=/root/.config/claude\
  --mount type=bind,src=.,dst=$(pwd)\
  --workdir $(pwd)\
  devenv:latest
