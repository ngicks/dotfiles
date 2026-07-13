#!/usr/bin/env bash

# Ensure system-level prerequisites that must exist BEFORE nix is installed,
# and repair the ones that are order-sensitive.
#
# zsh is the main one: the nix installer appends its profile hook only to
# global zsh rc files that exist at install time. On Debian/Ubuntu zsh reads
# /etc/zsh/zshrc (not /etc/zshrc, which the installer creates as a fallback),
# so installing zsh after nix leaves login shells without nix on PATH.
# This script installs zsh if missing and re-adds the nix hook if it is
# absent from the rc file zsh actually reads.

set -e

if ! sudo echo "unlocked" ; then
  echo "[WARNING] sudo failed; skipping system prerequisites"
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

if ! command -v zsh &> /dev/null; then
  echo "zsh not found; installing via $PKG_MANAGER"
  case "$PKG_MANAGER" in
      apt)
          sudo -E apt update
          sudo -E DEBIAN_FRONTEND=noninteractive apt install -y zsh
          ;;
      yum|dnf)
          sudo -E "$PKG_MANAGER" install -y zsh
          ;;
      pacman)
          sudo -E pacman -S --noconfirm zsh
          ;;
      *)
          echo "Error: package manager $PKG_MANAGER is not supported; install zsh manually"
          exit 1
          ;;
  esac
fi

# Repair the nix hook when zsh was installed after nix. Debian/Ubuntu zsh
# reads /etc/zsh/zshrc; other distros and macOS read /etc/zshrc.
nix_daemon_profile='/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
if [ -e "$nix_daemon_profile" ]; then
  if [ -d /etc/zsh ]; then
    global_zshrc="/etc/zsh/zshrc"
  else
    global_zshrc="/etc/zshrc"
  fi

  if ! grep -qs 'nix-daemon.sh' "$global_zshrc"; then
    echo "adding nix hook to $global_zshrc"
    sudo tee -a "$global_zshrc" > /dev/null <<EOF

# Nix
if [ -e '$nix_daemon_profile' ]; then
  . '$nix_daemon_profile'
fi
# End Nix
EOF
  fi
fi
