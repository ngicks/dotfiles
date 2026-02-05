#!/usr/bin/env bash

set -euo pipefail

dir=$(dirname $0)/crun

repo="https://github.com/containers/crun"
echo "updating ${repo}"
if [ ! -d "$dir" ]; then
  mkdir $dir
  git clone $repo $dir
fi

target_tag=$(cat $(dirname $0)/tag)

artifact_dir=$(dirname $0)/built/${target_tag}

if [ -d "$artifact_dir" ]; then
  if ${artifact_dir}/crun --version > /dev/null 2>&1; then
    echo "already built: crun ${target_tag}"
    exit 0
  fi
fi

mkdir -p  $artifact_dir

pushd $dir

git switch main
git pull --all --ff-only
git reset --hard tags/${target_tag}

./autogen.sh 
./configure --with-libkrun
make

./crun --version

popd

cp ./crun/crun ${artifact_dir}

pushd ${artifact_dir}
ln -fs ./crun krun
popd
