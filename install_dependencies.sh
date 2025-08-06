#!/bin/bash

sudo apt update 
sudo apt install -y make build-essential gcc clang xsel p7zip-full jq tmux libyaml-dev zlib1g-dev zsh

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

mkdir -p ~/bin
pushd ~/bin
curl -L https://github.com/TomWright/dasel/releases/download/v2.8.1/dasel_linux_amd64.gz -o dasel.gz
gzip -d ./dasel.gz
chmod +x dasel
popd
