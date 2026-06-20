#!/usr/bin/env bash

set -eCu

# apm's cache lives under __global_storage, which is inside the gitrepo tree that
# 20-gitrepo.sh already bind-mounts at its host path, so only the env var needs
# to be forwarded here.
APM_CACHE_DIR=${APM_CACHE_DIR:-${GITREPO_ROOT:-$HOME/gitrepo}/__global_storage/apm/cache}

printf "%s\n" "--env APM_CACHE_DIR=${APM_CACHE_DIR}"
