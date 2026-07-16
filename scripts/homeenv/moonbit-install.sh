#!/usr/bin/env bash

set -e

# Same layout as config/loginscript/env/00_moonbit.sh and devenv/Containerfile.
export MOON_HOME="${MOON_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/moonbit}"

if [ -x "${MOON_HOME}/bin/moon" ]; then
  echo "moon is already installed at ${MOON_HOME}/bin/moon"
  exit 0
fi

echo "installing the MoonBit toolchain to ${MOON_HOME}"
mkdir -p "${MOON_HOME}"
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash

"${MOON_HOME}/bin/moon" update
