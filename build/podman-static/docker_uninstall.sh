#!/bin/bash

set -Cue

for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  sudo apt-get remove $pkg;
done

sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
