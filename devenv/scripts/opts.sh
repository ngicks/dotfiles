#!/usr/bin/env bash

set -eCu

script_dir=$(cd "$(dirname "$0")" && pwd -P)

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
