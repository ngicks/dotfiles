#!/bin/env bash

set -Cue

tag=$(git -C $(dirname $0) describe --tags --abbrev=0 | cut -c 2-)

if ! podman volume exists claude-config; then
  podman volume create claude-config
fi

if ! podman volume exists gemini-config; then
  podman volume create gemini-config
fi

if ! podman volume exists codex-config; then
  podman volume create codex-config
fi

runner=$(dirname $0)/scripts/homeenv/run-devenv.sh

DEVENV_READONLY=1 runner "--mount type=bind,src=.,dst=$(pwd) --workdir $(pwd)"
