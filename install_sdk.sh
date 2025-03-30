#!/usr/bin/env bash

taret=sdk
action=install

if [ -n "$1" ]; then
  target=$1
fi

if [ -n "$2" ]; then
  action=$2
fi

git submodule update --init --recursive

os=$(uname -s)

# well known, linux, darwin(Mac OS).
# I'm not sure I will use other than those.
case ${os} in
  "Linux")
    os="linux";;
  "Darwin")
    os="darwin";;
esac

# In my environment there only are amd64(desktop/laptop), arm64(raspberry pi)
arch=$(uname -m)
case ${arch} in
  "x86_64")
    arch="amd64";;
  "x86_64-AT386")
    arch="amd64";;
  "aarch64_be")
    arch="arm64be";;
  "aarch64")
    arch="arm64";;
  "armv8b")
    arch="arm64";;
  "armv8l")
    arch="arm64";;
esac

mkdir -p ~/.local
mkdir -p ~/.config/env
if [[ ! -f ~/.config/env/path.sh ]]; then
  echo "#!/bin/bash" >> ~/.config/env/path.sh
  echo "" >> ~/.config/env/path.sh
  chmod +x ~/.config/env/path.sh
fi

mkdir -p ~/bin
cp ./ngpkgmgr/prebuilt/${os}-${arch}/* ~/bin
~/bin/ngpkgmgr --dir ./ngpkgmgr/preset/$target $action
