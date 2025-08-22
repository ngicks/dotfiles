#!/bin/env bash

set -Cue

if ! modprobe -q btrfs; then
  echo "btrfs kernel module not found"
  exit 1
fi

if ! command -v mkfs.btrfs >/dev/null 2>&1
then
  sudo apt update
  sudo apt install btrfs-progs -y
fi


IMAGE_LOC="/usr/local/etc/home_image/$(uname -n)/home.img"
LOOP_DEV="$(losetup -f)"
MNT_DIR="/mnt/snapshot-home/$(uname -n)"

sudo mkdir -p $(dirname ${IMAGE_LOC})

if [ ! -f ${IMAGE_LOC} ]; then
  sudo fallocate -l ${IMAGE_SIZE:-500G} ${IMAGE_LOC}
  sudo losetup ${LOOP_DEV} ${IMAGE_LOC}
  sudo mkfs.btrfs -L "home-$(uname -n)" ${LOOP_DEV}
  sudo mkdir -p ${MNT_DIR}
  # snapshot dir
  sudo mkdir -p "${MNT_DIR}/snapshots"
  sudo mount ${LOOP_DEV} ${MNT_DIR}
  sudo btrfs subvolume create "${MNT_DIR}/current"
  # optionally you can copy pre-existing home dir.
  # rsync -av --progress ~/ "/mnt/snapshot-home/$(uname -n)/current"
fi

