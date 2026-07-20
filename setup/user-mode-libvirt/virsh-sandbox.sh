#!/usr/bin/env bash

set -eCu

# virsh against the libvirt-sandbox session daemon. Requires membership in the
# libvirt-sandbox group (install.sh + re-login).
exec virsh -c "qemu+unix:///session?socket=/run/libvirt-sandbox/libvirt-sock" "$@"
