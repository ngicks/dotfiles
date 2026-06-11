#!/usr/bin/env bash

set -eCu

GITREPO_ROOT=${GITREPO_ROOT:-$HOME/gitrepo}
LIBVIRT_IMAGE_DIR=${LIBVIRT_IMAGE_DIR:-${GITREPO_ROOT}/__global_storage/var/lib/libvirt/images}

if [[ "${DEVENV_KVM:-}" != "1" ]]; then
  exit 0
fi

if [[ ! -e /dev/kvm ]]; then
  echo "[WARNING]: DEVENV_KVM=1 but /dev/kvm does not exist; KVM and libvirt image storage are not mounted" >&2
  exit 0
fi

mkdir -p "${LIBVIRT_IMAGE_DIR}"

printf "%s\n" "--device /dev/kvm"
printf "%s\n" "--group-add keep-groups"
printf "%s\n" "--mount type=bind,src=${LIBVIRT_IMAGE_DIR},dst=/var/lib/libvirt/images"
