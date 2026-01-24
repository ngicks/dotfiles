#!/bin/env bash

set -Cue

runner=$(dirname $0)/scripts/homeenv/run-devenv.sh

first_arg=${1:-""}
if [ "$#" -ge 1 ]; then
  shift
fi
DEVENV_READONLY=1 $runner "--mount type=bind,src=.,dst=$(pwd) --workdir $(pwd) ${first_arg}" "$@"
