#!/bin/env bash

set -Cue

runner=$(dirname $0)/scripts/homeenv/run-devenv.sh

DEVENV_READONLY=1 $runner "--mount type=bind,src=.,dst=$(pwd) --workdir $(pwd)"
