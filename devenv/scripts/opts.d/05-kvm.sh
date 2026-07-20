#!/usr/bin/env bash

set -eCu

if [[ "${DEVENV_KVM:-}" != "1" ]]; then
  exit 0
fi

if [[ ! -e /dev/kvm ]]; then
  echo "[WARNING]: DEVENV_KVM=1 but /dev/kvm does not exist; KVM and libvirt scratch storage are not mounted" >&2
  exit 0
fi

printf "%s\n" "--device /dev/kvm"
printf "%s\n" "--group-add keep-groups"
# All libvirt state (domain sockets, nvram, scratch disks) is per-container
# and dies with it: sharing it between containers would let one reach into
# another's VM monitor/agent sockets. Nothing is host-shared here; on request
# the in-container agent persists a VM by flattening its disk and dumping its
# definition into the (host-mounted) working tree, e.g.
#   qemu-img convert -O qcow2 /var/lib/libvirt/images/<x>.qcow2 ./vm/<x>.qcow2
#   virsh dumpxml <dom> > ./vm/<x>.xml
# Backing files under the working tree also work as-is: the tree is mounted
# at the same path in-container, so overlay backing references stay valid on
# both sides.
printf "%s\n" "--mount type=volume,dst=/var/lib/libvirt"
