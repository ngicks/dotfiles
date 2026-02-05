#!/usr/bin/env bash

set -euo pipefail

target_tag=$(cat $(dirname $0)/tag)

dir="${XDG_DATA_HOME:-$HOME/.local/share}/crun/versions"

mkdir -p $dir

cp -r $(dirname $0)/built/${target_tag} $dir

ln -fs ./$target_tag "${dir}/current"

abs_dir="$(cd ${dir}/current >/dev/null 2>&1; pwd)"
ln -fs ${abs_dir}/crun $HOME/.local/bin/override/crun
ln -fs ${abs_dir}/crun $HOME/.local/bin/override/krun

