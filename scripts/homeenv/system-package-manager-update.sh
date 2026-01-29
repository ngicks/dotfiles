#!/usr/bin/env bash

set -e

if ! sudo echo "unlocked" ; then
  echo "[WARNING] sudo failed"
fi

if [ "${SYSTEM_PKG_UPDATE_NOT_ALLOWED}" = "1" ]; then
  echo "skip: system package manager update"
  exit 0
fi

# Detect package manager
if command -v apt &> /dev/null; then
    PKG_MANAGER="apt"
elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
elif command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
else
    PKG_MANAGER="unknown"
fi

echo "Detected package manager: $PKG_MANAGER"

# Handle package manager
case "$PKG_MANAGER" in
    apt)
        echo "apt update"
        echo ""
        sudo -E apt update
        echo ""
        echo "apt dist-upgrade"
        echo ""
        sudo -E apt dist-upgrade -y
        echo ""
        echo "apt autoremove"
        echo ""
        sudo -E apt autoremove -y
        ;;
    *)
        echo "Error: package manager $PKG_MANAGER is not supported"
        exit 1
        ;;
esac

