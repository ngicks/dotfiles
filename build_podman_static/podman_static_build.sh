#!/bin/bash

sudo apt install -y uidmap

git submodule update --init --recursive

dir=$(dirname $0)/podman-static
pushd $dir
sudo make sudo make singlearch-tar
uid=$(id -u)
gid=$(id -g)
sudo chown ${uid}:${gid} -R ./build
cp -r ./build/asset/podman-linux-amd64/usr/local/ ~/.local/containers/
popd

cp -r ./build_podman_static/conf ~/.config/containers
deno -E -R=$HOME/.config/containers -W=$HOME/.config/containers ./build_podman_static/replace_conf.ts $HOME/.config/containers

echo "source ~/.config/containers/path.sh in start up script"
echo ". ~/.config/containers/path.sh"

