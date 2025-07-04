#!/bin/bash

if ! podman volume exists claude-cache; then
  podman volume create claude-cache
fi

podman run -it --rm --init\
  --mount type=volume,src=claude-cache,dst=/root/.config/claude\
  --mount type=bind,src=.,dst=$(pwd)\
  --workdir $(pwd)\
  devenv:latest
