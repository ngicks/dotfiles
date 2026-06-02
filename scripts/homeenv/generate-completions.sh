#!/usr/bin/env bash
#
# Generate zsh completion files into an fpath directory so that zsh's compinit
# can *autoload them lazily* on first Tab, instead of every interactive shell
# eval-ing `<tool> completion zsh` at startup (a binary fork + full parse per
# shell, which adds up with tmux/wezterm spawning many panes).
#
# Run at install/upgrade time (wired into homeenv-{install,upgrade}.sh), NOT at
# shell startup. The matching `fpath=(...)` entry lives in
# nix-craft/home/zsh/default.nix's compinitSnippet.
#
# To add a tool: append a "<command>|<args that emit a zsh completion script>"
# entry to `specs` below. Most cobra-backed tools use "completion zsh".

set -uo pipefail   # deliberately NOT -e: one tool failing must not abort the rest

out_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
mkdir -p "$out_dir"

specs=(
  # cobra-backed (`<tool> completion zsh`)
  "cmdman|completion zsh"
  "crabswarm|completion zsh"
  "golangci-lint|completion zsh"
  "helm|completion zsh"
  "kubectl|completion zsh"
  # clap-backed, different subcommand
  "mise|completion zsh"
  "ruff|generate-shell-completion zsh"
  # moonbit
  "moon|shell-completion --shell zsh"
)

# Resolve a tool to an executable absolute path.
#
# This script runs late in `homeup` (homeenv-upgrade.sh), in a shell whose PATH
# was fixed at startup: `mise activate` injected the *then-active* install dirs
# (e.g. .../installs/<tool>/<old-ver>/bin). Earlier in the same run, `mise up`
# may have upgraded a fast-moving tool (cmdman, the "rapidly-evolving prototype")
# and `mise prune -y` then DELETED that old version's dir. The stale PATH entry
# now dangles, so a plain `command -v` reports the freshly-updated tool as absent.
#
# Guard against that by re-resolving through mise (which reports the *current*
# active version) whenever the inherited PATH lookup fails. Non-mise tools
# (helm/kubectl from nix, moon from moonbit) just fall through to `command -v`.
resolve() {
  local cmd="$1" path
  if path="$(command -v "$cmd" 2>/dev/null)" && [ -x "$path" ]; then
    printf '%s\n' "$path"
    return 0
  fi
  if command -v mise >/dev/null 2>&1 \
    && path="$(mise which "$cmd" 2>/dev/null)" && [ -x "$path" ]; then
    printf '%s\n' "$path"
    return 0
  fi
  return 1
}

generated=()
skipped=()

for spec in "${specs[@]}"; do
  cmd="${spec%%|*}"
  args="${spec#*|}"

  if ! bin="$(resolve "$cmd")"; then
    skipped+=("$cmd(absent)")
    continue
  fi

  tmp="$(mktemp)"
  # stdin from /dev/null so a binary that probes stdin (e.g. detecting a pipe)
  # gets EOF and proceeds instead of blocking; same guard as
  # mise-install-f-if-missing.sh.
  # Invoke the resolved absolute path (not "$cmd"), so the generation step is
  # likewise immune to the stale-PATH window described in resolve() above.
  # shellcheck disable=SC2086  # args intentionally word-split into argv
  if "$bin" $args </dev/null >"$tmp" 2>/dev/null && [ -s "$tmp" ]; then
    mv "$tmp" "$out_dir/_$cmd"
    generated+=("$cmd")
  else
    rm -f "$tmp"
    skipped+=("$cmd(no-output)")
  fi
done

# `compinit -C` (see compinitSnippet) trusts the cached .zcompdump and will NOT
# pick up newly written _<tool> files until that dump is rebuilt. Invalidate it
# so the next interactive shell regenerates it.
rm -f "$HOME/.zcompdump"* 2>/dev/null || true
if [ -n "${ZDOTDIR:-}" ]; then
  rm -f "${ZDOTDIR}/.zcompdump"* 2>/dev/null || true
fi

echo "completions -> $out_dir"
echo "  generated: ${generated[*]:-none}"
if [ "${#skipped[@]}" -gt 0 ]; then
  echo "  skipped:   ${skipped[*]}"
fi
