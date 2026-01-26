#!/bin/bash

set -Ceu

case "${PINENTRY_USER_DATA-}" in
*TTY*)
  exec pinentry-curses "$@"
  ;;
*TMUX_POPUP*)
  exec $HOME/.nix-profile/bin/tmux-popup-pinentry-curses "$@"
  ;;
*ZELLIJ_POPUP*)
  exec $HOME/.nix-profile/bin/zellij-popup-pinentry-curses "$@"
  ;;
esac

exec pinentry-qt "$@"

