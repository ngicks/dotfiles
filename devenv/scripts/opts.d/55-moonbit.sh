#!/usr/bin/env bash

set -eCu

MOON_HOME=${MOON_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/moonbit}

# Share the host toolchain at the identical path so `_build` artifacts, which
# embed absolute MOON_HOME paths, resolve on both sides. Without this the
# container's baked toolchain (/root/.local/share/moonbit) poisons `_build`
# with paths the host cannot resolve, and vice versa.
#
# No mkdir guard on purpose: an auto-created empty MOON_HOME plus the --env
# override would leave the container with no toolchain at all. Fall through to
# the baked one instead when the host has no install
# (scripts/homeenv/moonbit-install.sh).
if [[ -x "${MOON_HOME}/bin/moon" ]]; then
  printf "%s\n" "--env MOON_HOME=${MOON_HOME}"
  printf "%s\n" "--mount type=bind,src=${MOON_HOME},dst=${MOON_HOME}"
fi
