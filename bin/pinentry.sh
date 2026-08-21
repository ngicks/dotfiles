#!/usr/bin/env bash

set -Ceu

case "${PINENTRY_USER_DATA-}" in
*TTY*)
  exec pinentry-curses "$@"
  ;;
*TMUX_POPUP*)
  exec $HOME/.local/share/mise/shims/run-in-popup pinentry  --backend "tmux-popup"
  ;;
*ZELLIJ_POPUP*)
  exec $HOME/.local/share/mise/shims/run-in-popup pinentry  --backend "zellij"
  ;;
esac

exec pinentry-qt "$@"

