#!/usr/bin/env bash

set -eCu

# The loginscript env sets these in interactive shells, but this may run from
# a bare shell (set -u would abort); fall back to go's own defaults.
GOPATH=${GOPATH:-$HOME/go}
GOBIN=${GOBIN:-${GOPATH}/bin}

# A bind mount with a missing src fails the whole `podman run`; create it.
mkdir -p "${GOPATH}"

printf "%s\n" "--env GOBIN=${GOBIN}"
printf "%s\n" "--env GOPATH=${GOPATH}"
printf "%s\n" "--mount type=bind,src=${GOPATH},dst=${GOPATH}"
