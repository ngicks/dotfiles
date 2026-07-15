#!/usr/bin/env bash

set -Ceu

case "${PINENTRY_USER_DATA-}" in
*TTY*)
  exec pinentry-curses "$@"
  ;;
*TMUX_POPUP*)
  exec $HOME/.local/share/mise/shims/tmux-popup-pinentry-curses "$@"
  ;;
*ZELLIJ_POPUP*)
  exec $HOME/.local/share/mise/shims/zellij-popup-pinentry-curses "$@"
  ;;
esac

exec pinentry-qt "$@"

