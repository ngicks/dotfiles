#!/usr/bin/env bash

set -eCu

# huggingface_hub keeps the hub/xet/datasets caches under HF_HOME. That lives
# under __global_storage, inside the gitrepo tree that 20-gitrepo.sh already
# bind-mounts at its host path, so only the env var needs to be forwarded.
HF_HOME=${HF_HOME:-${GITREPO_ROOT:-$HOME/gitrepo}/__global_storage/huggingface}

printf "%s\n" "--env HF_HOME=${HF_HOME}"
# The login token defaults to <HF_HOME>/token; keep it out of the shared cache
# and in the hf-token volume that 90-volumes.sh mounts at
# /root/.config/huggingface instead.
printf "%s\n" "--env HF_TOKEN_PATH=/root/.config/huggingface/token"
