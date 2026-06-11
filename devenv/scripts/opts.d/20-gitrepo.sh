#!/usr/bin/env bash

set -eCu

# The whole gitrepo tree is mounted into the container at its host path so that
# package stores under __global_storage and projects under gitrepo can share one
# filesystem where hardlinks work.
GITREPO_ROOT=${GITREPO_ROOT:-$HOME/gitrepo}

mkdir -p "${GITREPO_ROOT}"

printf "%s\n" "--mount type=bind,src=${GITREPO_ROOT},dst=${GITREPO_ROOT}"
