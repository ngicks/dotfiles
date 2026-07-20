#!/usr/bin/env bash

set -eCu

# systemctl --user inside the libvirt-sandbox user session, e.g.
#   ./sandbox-systemctl.sh status libvirtd.service
# Re-execs itself under sudo when not already root.

if [[ $(id -u) -ne 0 ]]; then
  exec sudo "$0" "$@"
fi

uid=$(id -u libvirt-sandbox)
exec runuser -u libvirt-sandbox -- \
  env "XDG_RUNTIME_DIR=/run/user/${uid}" systemctl --user "$@"
