#!/bin/bash

set -Cue

if ! podman volume exists claude-config; then
  podman volume create claude-config
fi

if ! podman volume exists gemini-config; then
  podman volume create gemini-config
fi

podman run -it --rm --init\
  --mount type=bind,src=$HOME/.config/env/,dst=/root/.config/env,ro\
  --mount type=bind,src=$HOME/.bashrc,dst=/root/.bashrc,ro\
  --mount type=volume,src=claude-config,dst=/root/.config/claude\
  --mount type=volume,src=gemini-config,dst=/root/.gemini\
  --mount type=bind,src=.,dst=$(pwd)\
  --workdir $(pwd)\
  devenv:latest
