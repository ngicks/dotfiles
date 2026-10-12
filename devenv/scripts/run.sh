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

# cmdman sets CMDMAN_* (e.g. CMDMAN_CMD_NAME) only in the environment of the
# running command, after it has interpolated the compose file. Expanding them
# here lets the compose file put them in the options. Every other $ stays
# literal so options typed by hand keep their meaning.
if [[ "${first_arg}" == *'$'* ]]; then
  first_arg=$(printf "%s" "${first_arg}" | envsubst "$(printf '${%s} ' ${!CMDMAN_@})")
fi

DEVENV_READONLY=1 exec $runner "${mount_opt} --workdir $(pwd) ${first_arg}" "$@"
