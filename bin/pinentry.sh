#!/usr/bin/env bash

set -Ceu

case "${PINENTRY_USER_DATA-}" in
*TTY*)
  exec pinentry-curses "$@"
  ;;
*TMUX_POPUP*)
  exec $HOME/.local/share/mise/shims/run-in-popup pinentry --backend "tmux-popup" -- "$@"
  ;;
*ZELLIJ_POPUP*)
  exec $HOME/.local/share/mise/shims/run-in-popup pinentry --backend "zellij" -- "$@"
  ;;
esac

# gpg-agent passes the requesting client's display as --display. The agent's
# own DISPLAY / WAYLAND_DISPLAY come from its startup env and may be stale.
display=""
prev=""
for arg in "$@"; do
  case "$arg" in
  --display=*) display="${arg#--display=}" ;;
  *) [ "$prev" = "--display" ] && display="$arg" ;;
  esac
  prev="$arg"
done
display="${display:-${DISPLAY-}${WAYLAND_DISPLAY-}}"

# pinentry-qt cannot draw without a display. A call that reaches here without
# any (e.g. a non-interactive ssh command) still has a tty to prompt on.
if [ -z "$display" ]; then
  exec pinentry-curses "$@"
fi

exec pinentry-qt "$@"

