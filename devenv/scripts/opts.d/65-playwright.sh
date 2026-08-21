#!/usr/bin/env bash

set -eCu

GITREPO_ROOT=${GITREPO_ROOT:-$HOME/gitrepo}

PLAYWRIGHT_BROWSERS_PATH=${GITREPO_ROOT}/__global_storage/playwright/browsers

mkdir -p "${PLAYWRIGHT_BROWSERS_PATH}"

# The browsers live inside the gitrepo tree, which 20-gitrepo.sh already
# bind-mounts at its host path; only the env var needs handing in.
printf "%s\n" "--env PLAYWRIGHT_BROWSERS_PATH=${PLAYWRIGHT_BROWSERS_PATH}"
