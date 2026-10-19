#!/usr/bin/env bash

set -eCu

# Lima state (LIMA_HOME, guest disks) lives under the lima user's home. An
# anonymous volume keeps those multi-GB disk images out of the container's
# overlay layer; no src means it is removed together with the --rm container,
# the same per-container lifetime 05-kvm.sh gives libvirt state. Podman copies
# the image's /home/lima into the fresh volume, so the lima uid/gid ownership
# set in nix-craft/devenv-home-base.nix carries over.
printf "%s\n" "--mount type=volume,dst=/home/lima"
