#!/bin/bash

set -Cue

apt_updated="0"
apt_update_once() {
  if [ ${apt_updated} = "0" ]; then 
    apt_updated="1" 
    sudo -E apt update
  fi
}

echo "installing docker if it does not exist"
if ! docker version >/dev/null 2>&1; then
  apt_updated="1"
  $(dirname $0)/docker_install.sh
  sudo systemctl start docker
  sleep 3
  # remain from previous installation
  docker buildx rm podman-builder || true
fi

echo "installing uidmap if it does not exist"
if ! command -v newgidmap >/dev/null 2>&1; then
  apt_update_once
  sudo -E apt install -y uidmap
fi

dir=$(dirname $0)/podman-static

echo "updating github.com/mgoltzsche/podman-static"
if [ ! -d "$dir" ]; then
  mkdir $dir
  git clone https://github.com/mgoltzsche/podman-static $dir
fi

target_tag=$(cat $(dirname $0)/tag)

pushd $dir

git switch master
git pull --all --ff-only
git reset --hard tags/${target_tag}

if docker info | grep rootless > /dev/null 2>&1; then
  echo "bulding podman as rootless"
  make
  make singlearch-tar
else
  echo "bulding podman as rootful"
  sudo make
  sudo make singlearch-tar
  uid=$(id -u)
  gid=$(id -g)
  sudo chown ${uid}:${gid} -R ./build
fi

popd

artifact_dir=$(dirname $0)/podman-static/build/asset/podman-linux-amd64
conf_dir=${artifact_dir}/etc/containers
user_service_dir=${artifact_dir}/usr/local/lib/systemd/user

# confSrcDir, podmanConfigPath, targetHome, targetXdgDataHome
deno -E -R=$(dirname $0)/conf -W=${conf_dir} $(dirname $0)/copy_conf_interpolating.ts \
  $(dirname $0)/conf \
  ${conf_dir} \
  ${TARGET_HOME:-$HOME} \
  ${TARGET_XDG_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}}

user_service_dir=${artifact_dir}/usr/local/lib/systemd/user
for u in $(ls ${user_service_dir}); do
  deno -R=${user_service_dir}/${u} -W=${user_service_dir}/${u} $(dirname $0)/insert_environment_file.ts \
    ${user_service_dir}/${u} \
    ${TARGET_HOME:-$HOME}/.config/containers/path.env \
    ${TARGET_HOME:-$HOME}/.local/containers/bin/podman
done

tgt_dir=${TARGET_ARTIFACT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/podman}/${target_tag}
mkdir -p ${tgt_dir}
cp -r ${artifact_dir}/* ${tgt_dir}/
