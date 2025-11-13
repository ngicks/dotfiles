#!/bin/bash

set -Cue

sudo apt install -y uidmap

git submodule update --init --recursive

dir=$(dirname $0)/podman-static
pushd $dir

if docker info | grep rootless > /dev/null 2>&1; then
  make
  make singlearch-tar
else
  sudo make
  sudo make singlearch-tar
  uid=$(id -u)
  gid=$(id -g)
  sudo chown ${uid}:${gid} -R ./build
fi

cp -r ./build/asset/podman-linux-amd64/usr/local/ ~/.local/containers/
popd

cp -r ./build_podman_static/conf ~/.config/containers
deno -E -R=$HOME/.config/containers -W=$HOME/.config/containers ./build_podman_static/replace_conf.ts $HOME/.config/containers

echo "source ~/.config/containers/path.sh in start up script"
echo ". ~/.config/containers/path.sh"

