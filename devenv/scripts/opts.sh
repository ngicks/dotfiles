#!/usr/bin/env bash

set -eCu

script_dir=$(cd "$(dirname "$0")" && pwd -P)

# crabswarm manages the whole gitrepo tree; resolve its root once here so
# every opts.d script agrees on it. Fall back to the well-known path when
# crabswarm is not on PATH.
if [[ -z "${GITREPO_ROOT:-}" ]]; then
  GITREPO_ROOT=$(crabswarm config --format '{{.GitRepoBaseDir}}' 2>/dev/null) || GITREPO_ROOT=""
fi
export GITREPO_ROOT="${GITREPO_ROOT:-$HOME/gitrepo}"

# Scripts listed here are skipped without being removed from opts.d.
exclude_scripts=()

for opt_script in "${script_dir}/opts.d/"*.sh; do
  # ${arr[@]+...} instead of a bare expansion: empty array + set -u errors on
  # bash 3.x (macOS).
  for excluded in ${exclude_scripts[@]+"${exclude_scripts[@]}"}; do
    if [[ "$(basename "$opt_script")" == "$excluded" ]]; then
      continue 2
    fi
  done
  "$opt_script"
done
