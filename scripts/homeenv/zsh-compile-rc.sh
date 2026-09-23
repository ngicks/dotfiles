#!/usr/bin/env bash
#
# Pre-compile the zsh startup files with `zcompile` so each new shell loads
# bytecode instead of re-parsing every sourced file. This matters here because
# the startup sequence sources dozens of small files (loginscript/*).
#
# Compile targets are the paths zsh actually sources: the startup files in
# ${ZDOTDIR:-$HOME} and the loginscript tree under ~/.config. zsh looks for
# `<file>.zwc` right next to `<file>`, so the compiled output must sit beside
# the ~/.config symlinks -- compiling the sources in ~/.dotfiles would put the
# .zwc where zsh never looks.
#
# Run this after every home-manager switch. The symlinks in ~/.config point
# into the nix store, whose files carry a 1970 mtime; zsh prefers a .zwc
# whenever it is not older than its source, so a .zwc left over from a previous
# generation would silently shadow the new file forever. Hence: delete every
# .zwc first, then recompile everything.
#
# ~/.config/env is deliberately excluded: it holds machine-local, hand-edited
# files (edits already outrank a stale .zwc by mtime), and zcompile writes
# world-readable output, which would widen the permissions of secret-bearing
# files such as keys.sh.

set -uo pipefail   # deliberately NOT -e: one file failing must not abort the rest

zdotdir="${ZDOTDIR:-$HOME}"
loginscript_dir="${XDG_CONFIG_HOME:-$HOME/.config}/loginscript"

# On a fresh install the calling shell may not have the nix profile on PATH yet.
if zsh_bin="$(command -v zsh 2>/dev/null)"; then
  :
elif [ -x "$HOME/.nix-profile/bin/zsh" ]; then
  zsh_bin="$HOME/.nix-profile/bin/zsh"
else
  echo "zsh-compile-rc: zsh not found; skipping" >&2
  exit 0
fi

targets=()
for f in .zshenv .zprofile .zshrc .zlogin .zlogout; do
  [ -f "$zdotdir/$f" ] && targets+=("$zdotdir/$f")
done

if [ -d "$loginscript_dir" ]; then
  while IFS= read -r f; do
    targets+=("$f")
  done < <(find -L "$loginscript_dir" -type f -name '*.sh' | sort)
fi

for f in .zshenv .zprofile .zshrc .zlogin .zlogout; do
  rm -f "$zdotdir/$f.zwc"
done
if [ -d "$loginscript_dir" ]; then
  find "$loginscript_dir" -type f -name '*.zwc' -delete
fi

compiled=()
failed=()
for f in "${targets[@]}"; do
  if "$zsh_bin" -fc 'zcompile -- "$1"' -- "$f" 2>/dev/null; then
    compiled+=("$f")
  else
    failed+=("$f")
  fi
done

echo "zsh rc compiled: ${#compiled[@]} file(s)"
if [ "${#failed[@]}" -gt 0 ]; then
  echo "  failed: ${failed[*]}" >&2
fi
