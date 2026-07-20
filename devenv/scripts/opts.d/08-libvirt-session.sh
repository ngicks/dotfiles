#!/usr/bin/env bash

set -eCu

# Forward the libvirt-sandbox user session daemon (setup/user-mode-libvirt)
# into the container so the in-container virsh drives VMs running as that
# user. Opt in with DEVENV_LIBVIRT_SESSION=1.
LIBVIRT_SANDBOX_SOCKET_DIR=${LIBVIRT_SANDBOX_SOCKET_DIR:-/run/libvirt-sandbox}
LIBVIRT_SANDBOX_IMAGE_DIR=${LIBVIRT_SANDBOX_IMAGE_DIR:-/var/lib/libvirt-sandbox/images}

if [[ "${DEVENV_LIBVIRT_SESSION:-}" != "1" ]]; then
  exit 0
fi

if [[ ! -S "${LIBVIRT_SANDBOX_SOCKET_DIR}/libvirt-sock" ]]; then
  echo "[WARNING]: DEVENV_LIBVIRT_SESSION=1 but ${LIBVIRT_SANDBOX_SOCKET_DIR}/libvirt-sock is not a socket (run setup/user-mode-libvirt/install.sh); libvirt session is not forwarded" >&2
  exit 0
fi

# Mount the dir, not the socket file: a daemon restart recreates the socket
# inode and a file bind-mount would go stale.
printf "%s\n" "--mount type=bind,src=${LIBVIRT_SANDBOX_SOCKET_DIR},dst=${LIBVIRT_SANDBOX_SOCKET_DIR}"
printf "%s\n" "--env LIBVIRT_DEFAULT_URI=qemu+unix:///session?socket=${LIBVIRT_SANDBOX_SOCKET_DIR}/libvirt-sock"

if [[ -d "${LIBVIRT_SANDBOX_IMAGE_DIR}" ]]; then
  # Same path inside so pool/volume paths stay valid on both sides.
  printf "%s\n" "--mount type=bind,src=${LIBVIRT_SANDBOX_IMAGE_DIR},dst=${LIBVIRT_SANDBOX_IMAGE_DIR}"
fi

# Socket access relies on the invoking user's libvirt-sandbox supplementary
# group surviving into the rootless container. 05-kvm.sh already emits
# keep-groups when active; podman rejects a duplicate keep-groups entry, so
# only add it when 05-kvm.sh did not.
if [[ "${DEVENV_KVM:-}" != "1" || ! -e /dev/kvm ]]; then
  printf "%s\n" "--group-add keep-groups"
fi
