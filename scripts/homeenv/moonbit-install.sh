#!/usr/bin/env bash
# Install or upgrade MoonBit toolchain.
# Installs to $MOON_HOME (default: ~/.local/share/moonbit).
# Idempotent: upgrades if already installed.

set -euo pipefail

export MOON_HOME="${MOON_HOME:-$HOME/.local/share/moonbit}"

if [[ -x "$MOON_HOME/bin/moon" ]]; then
  echo "MoonBit already installed, upgrading..."
  "$MOON_HOME/bin/moon" upgrade
else
  echo "Installing MoonBit to $MOON_HOME..."
  curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash

  # Clean up any shell RC modifications the installer may have added
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$rc" ]]; then
      # Remove lines related to moon/moonbit PATH additions
      sed -i '/\.moon/d' "$rc" 2>/dev/null || true
      sed -i '/moonbit/d' "$rc" 2>/dev/null || true
    fi
  done
fi

echo "MoonBit version: $("$MOON_HOME/bin/moon" version)"
