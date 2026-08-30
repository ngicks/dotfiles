#!/usr/bin/env bash

set -eCu

# Paired with the daily-update task that caches `user.name`/`user.email` from
# the host into this directory, so git in the container commits as the host user
# without the identity being baked into the image.
#
# This shadows the home-manager-generated /root/.config/git/config in the image;
# that file only ever reflects `programs.git.enable = true` and is essentially
# empty, so nothing of value is hidden.
#
# A bind mount with a missing src fails the whole `podman run`; create it. The
# directory stays absent until the daily task has run once, and an empty
# directory mounted here is harmless -- git tolerates a missing config file.
git_identity_dir=${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/git

mkdir -p "${git_identity_dir}"

printf "%s\n" "--mount type=bind,src=${git_identity_dir},dst=/root/.config/git,ro"
