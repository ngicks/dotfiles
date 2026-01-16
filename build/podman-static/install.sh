#!/bin/bash

set -Cue

dir=$(dirname $0)

target_tag=${1:-$(cat ${dir}/tag)}
podman_base=${TARGET_ARTIFACT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/podman}
built_dir=${podman_base}/${target_tag}

if [[ ! -d ${built_dir} ]]; then
  echo "not built: buidling"
  ${dir}/build.sh
fi

current_link=${podman_base}/current

echo "unlinking ${current_link} if it already exists"
if [[ -e ${current_link} ]]; then
  if [[ ! -L ${current_link} ]]; then
    echo "failing: target is not symlink: ${current_link}"
    exit 2
  fi
  rm ${current_link}
fi

ln -s ${target_tag} ${current_link}

config_dir=${XDG_CONFIG_HOME:-$HOME/.config}/containers

echo "unlinking ${config_dir} if it already exists"
if [[ -e ${config_dir} ]]; then
  if [[ ! -L ${config_dir} ]]; then
    echo "failing: target is not symlink: ${config_dir}"
    exit 2
  fi
  rm ${config_dir}
fi

ln -s ${current_link}/etc/containers $config_dir

echo "unlinking ${HOME}/.local/containers if it already exists"
if [[ -e ${HOME}/.local/containers ]]; then
  if [[ ! -L ${HOME}/.local/containers ]]; then
    echo "failing: target is not symlink: ${HOME}/.local/containers"
    exit 2
  fi
  rm ${HOME}/.local/containers
fi

ln -s ${current_link}/usr/local ${HOME}/.local/containers

mkdir -p ${HOME}/.config/systemd/user

user_service_dir=${built_dir}/usr/local/lib/systemd/user
for u in $(ls ${user_service_dir}); do
  if [[ -e ${HOME}/.config/systemd/user/${u} ]]; then
    rm ${HOME}/.config/systemd/user/${u}
  fi
  ln -s ${HOME}/.local/containers/lib/systemd/user/${u} ${HOME}/.config/systemd/user/${u}
done

