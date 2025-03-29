#!/usr/bin/env bash

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

# actually it does not suport other than linux_amd64.
# I don't have mac. thus, I can not build for it.
./ngpkgmgr/prebuilt/${os}-${arch}/ngpkgmgr --dir ./ngpkgmgr/preset/sdk install
