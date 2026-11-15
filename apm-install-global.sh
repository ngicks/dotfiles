#!/usr/bin/env bash

set -Cue

script_dir=$(cd "$(dirname "$0")" && pwd -P)

submodule=agents-package

# --remote moves the submodule to the tip of its tracked branch instead of the
# commit recorded in this repository, so every installation uses the latest
# installer. A plain `git pull` inside the submodule fails on its detached HEAD.
git -C "${script_dir}" submodule update --init --remote -- "${submodule}"

installer="${script_dir}/${submodule}/install-myenv.sh"

if [[ ! -f "${installer}" ]]; then
  echo "$(basename "$0"): ${installer} not found" >&2
  exit 1
fi

# The script is bind-mounted on its own, so the container runs exactly the file
# checked above whatever else devenv mounts. The destination sits outside /tmp
# because 10-core.sh replaces /tmp with a fresh tmpfs.
dst=/install-myenv.sh

# A login shell loads loginscript, which puts the mise shims (and so apm) on PATH.
exec "${script_dir}/devenv_run.sh" \
  "--mount type=bind,src=${installer},dst=${dst},ro --env MYENV_UPDATE" \
  -lc "exec bash ${dst}"
