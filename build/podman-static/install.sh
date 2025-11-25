#!/bin/bash

set -Cue

dir=$(dirname $0)

# TODO: add os/arch detection?
artifact_dir=${dir}/podman-static/build/asset/podman-linux-amd64

if [[ ! -d ${artifact_dir} ]]; then
  echo "not built: buidling"
  ${dir}/build.sh
fi

artifact_version=$(${dir}/podman-static/build/asset/podman-linux-amd64/usr/local/bin/podman --version | sed -s 's/podman version //')

tgt_dir=${XDG_DATA_HOME:-$HOME/.local/share}/podman/${artifact_version}

config_dir=${XDG_CONFIG_HOME:-$HOME/.config}/containers

echo "unlinking ${config_dir} if it already exists"
if [[ -e ${config_dir} ]]; then
  if [[ ! -L ${config_dir} ]]; then
    echo "failing: target is not symlink: ${config_dir}"
    exit 2
  fi
  rm ${config_dir}
fi

ln -s ${tgt_dir}/etc/containers $config_dir

echo "unlinking ${HOME}/.local/containers if it already exists"
if [[ -e ${HOME}/.local/containers ]]; then
  if [[ ! -L ${HOME}/.local/containers ]]; then
    echo "failing: target is not symlink: ${HOME}/.local/containers"
    exit 2
  fi
  rm ${HOME}/.local/containers
fi

ln -s ${tgt_dir}/usr/local ${HOME}/.local/containers

mkdir -p ${HOME}/.config/systemd/user

user_service_dir=${artifact_dir}/usr/local/lib/systemd/user
for u in $(ls ${user_service_dir}); do
  if [[ -e ${user_service_dir}/${u} ]]; then 
    rm ${HOME}/.config/systemd/user/${u}
  fi
  ln -s ${HOME}/.local/containers/lib/systemd/user/${u} ${HOME}/.config/systemd/user/${u}
done

# cp -r ./build/asset/podman-linux-amd64/usr/local/ ~/.local/containers/
#
# cp -r ./build_podman_static/conf ~/.config/containers
# 
#
# echo "source ~/.config/containers/path.sh in start up script"
# echo ". ~/.config/containers/path.sh"
