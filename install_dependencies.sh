#!/bin/bash

set -e

# Detect package manager
if command -v apt &> /dev/null; then
    PKG_MANAGER="apt"
elif command -v brew &> /dev/null; then
    PKG_MANAGER="brew"
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
        echo "Starting installation for apt-based system..."
        . ./dep/apt.sh
        . ./dep/common.sh
        ;;
    brew)
        echo "Starting installation for brew-based system..."
        . ./dep/brew.sh
        . ./dep/common.sh
        for f in ./dep/common/*.sh; do
          . $f
        done
        ;;
    *)
        echo "Error: package manager $PKG_MANAGER is not supported"
        exit 1
        ;;
esac

echo "Installation completed successfully!"
