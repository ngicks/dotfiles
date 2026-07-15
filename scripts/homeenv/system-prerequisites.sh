#!/usr/bin/env bash

set -e

if ! sudo echo "unlocked" ; then
  echo "[WARNING] sudo failed; skipping system prerequisites"
  exit 0
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

case "$PKG_MANAGER" in
    apt)
        packages=(build-essential curl git ca-certificates xz-utils unzip zsh)
        missing=()
        for pkg in "${packages[@]}"; do
            if ! dpkg -s "$pkg" &> /dev/null; then
                missing+=("$pkg")
            fi
        done
        if [ "${#missing[@]}" -gt 0 ]; then
            echo "installing via apt: ${missing[*]}"
            sudo -E apt update
            sudo -E DEBIAN_FRONTEND=noninteractive apt install -y "${missing[@]}"
        fi
        ;;
    yum|dnf)
        packages=(gcc gcc-c++ make curl git ca-certificates xz unzip zsh)
        echo "installing via $PKG_MANAGER: ${packages[*]}"
        sudo -E "$PKG_MANAGER" install -y "${packages[@]}"
        ;;
    pacman)
        packages=(base-devel curl git ca-certificates xz unzip zsh)
        echo "installing via pacman: ${packages[*]}"
        sudo -E pacman -S --noconfirm --needed "${packages[@]}"
        ;;
    *)
        echo "[WARNING] package manager $PKG_MANAGER is not supported;"
        echo "[WARNING] install these manually: a C/C++ toolchain, curl, git, ca-certificates, xz, unzip, zsh"
        ;;
esac

nix_daemon_profile='/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
nix_single_user_profile="${HOME}/.nix-profile/etc/profile.d/nix.sh"

nix_newly_installed=false
if ! command -v nix &> /dev/null \
    && [ ! -e "$nix_daemon_profile" ] \
    && [ ! -e "$nix_single_user_profile" ]; then
  echo "nix not found; installing (multi-user/daemon mode)"
  sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon --yes
  nix_newly_installed=true
fi

# Repair the nix hook when zsh was installed after nix. Debian/Ubuntu zsh
# reads /etc/zsh/zshrc; other distros and macOS read /etc/zshrc.
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

if [ "$nix_newly_installed" = true ]; then
  echo ""
  echo "=================================================================="
  echo " nix was just installed but is not on PATH in this shell yet."
  echo " Restart your shell (or open a new terminal), then re-execute:"
  echo ""
  echo "   ./homeenv-install.sh"
  echo ""
  echo "=================================================================="
  exit 1
fi

if ! command -v nix &> /dev/null; then
  echo ""
  echo "=================================================================="
  echo " nix is installed but not on PATH in this shell."
  echo " Restart your shell (or open a new terminal), then re-execute:"
  echo ""
  echo "   ./homeenv-install.sh"
  echo ""
  echo "=================================================================="
  exit 1
fi
