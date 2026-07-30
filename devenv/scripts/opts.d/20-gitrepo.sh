#!/usr/bin/env bash

set -eCu

# The whole gitrepo tree is mounted into the container at its host path so that
# package stores under __global_storage and projects under gitrepo can share one
# filesystem where hardlinks work.
GITREPO_ROOT=${GITREPO_ROOT:-$HOME/gitrepo}

mkdir -p "${GITREPO_ROOT}"

# Hand the host path to the container so the in-container loginscript does not
# re-derive it from the container's own HOME/crabswarm, and point the
# container's crabswarm at the mounted tree so `crabswarm git clone`/`list`
# operate on the same repos as the host.
printf "%s\n" "--env GITREPO_ROOT=${GITREPO_ROOT}"
printf "%s\n" "--env CRABSWARM_GIT_REPO_BASE_DIR=${GITREPO_ROOT}"
printf "%s\n" "--mount type=bind,src=${GITREPO_ROOT},dst=${GITREPO_ROOT}"
