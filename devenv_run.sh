#!/usr/bin/env bash

set -Cue

exec "$(dirname "$0")/devenv/scripts/run.sh" "$@"
