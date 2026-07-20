#!/usr/bin/env bash

set -eCu

script_dir=$(cd "$(dirname "$0")" && pwd -P)

opt_scripts=(
  00-timezone.sh
  05-kvm.sh
  06-incus.sh
  07-podman.sh
  08-libvirt-session.sh
  10-core.sh
  15-proxy.sh
  20-gitrepo.sh
  30-nvim.sh
  40-mise.sh
  45-apm.sh
  50-runtimes.sh
  60-node.sh
  70-go.sh
  90-volumes.sh
)

for opt_script in "${opt_scripts[@]}"; do
  "${script_dir}/opts.d/${opt_script}"
done
