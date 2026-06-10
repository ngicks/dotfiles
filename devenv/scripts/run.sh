#!/usr/bin/env bash

set -Cue

runner=$(dirname $0)/run-devenv.sh

# run-devenv.sh bind-mounts the whole gitrepo tree, so a project inside it is
# already available in the container; only mount the cwd when it lives outside
# that tree.
gitrepo_root=${GITREPO_ROOT:-$HOME/gitrepo}
case "$(pwd)/" in
  "${gitrepo_root}/"*) mount_opt="" ;;
  *) mount_opt="--mount type=bind,src=$(pwd),dst=$(pwd)" ;;
esac

first_arg=${1:-""}
if [ "$#" -ge 1 ]; then
  shift
fi

DEVENV_READONLY=1 $runner "${mount_opt} --workdir $(pwd) ${first_arg}" "$@"
