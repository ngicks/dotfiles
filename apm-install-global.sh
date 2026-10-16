#!/usr/bin/env bash

set -Cue

script_dir=$(cd "$(dirname "$0")" && pwd -P)

if [[ -z "${GITREPO_ROOT:-}" ]]; then
  GITREPO_ROOT=$(crabswarm config --format '{{.GitRepoBaseDir}}' 2>/dev/null) || GITREPO_ROOT=""
fi
GITREPO_ROOT=${GITREPO_ROOT:-$HOME/gitrepo}

installer="${GITREPO_ROOT}/github.com/ngicks/agents-package/main/install-myenv.sh"

if [[ ! -f "${installer}" ]]; then
  echo "$(basename "$0"): ${installer} not found; clone it with 'crabswarm git clone github.com/ngicks/agents-package'" >&2
  exit 1
fi

# The script is bind-mounted on its own instead of relying on the gitrepo tree
# mount, so the container runs exactly the file checked above even when
# opts.d/20-gitrepo.sh is excluded. The destination sits outside /tmp because
# 10-core.sh replaces /tmp with a fresh tmpfs.
dst=/install-myenv.sh

# A login shell loads loginscript, which puts the mise shims (and so apm) on PATH.
exec "${script_dir}/devenv_run.sh" \
  "--mount type=bind,src=${installer},dst=${dst},ro --env MYENV_UPDATE" \
  -lc "exec bash ${dst}"
