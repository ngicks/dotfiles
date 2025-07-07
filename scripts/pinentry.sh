#!/bin/bash

set -Ceu

# Use pinentry-tty if $PINENTRY_USER_DATA contains USE_TTY=1
case "${PINENTRY_USER_DATA-}" in
*TTY=1*)
	# Note: Change to pinentry-curses if a Curses UI is preferred.
	exec pinentry-curses "$@"
	;;
*TMUX_POPUP=1*)
  tempdir=''
  cleanup() {
    [ "$tempdir" ] || return 0
    rm -rf "$tempdir"
  }
  trap "cleanup" EXIT
  tempdir=$(mktemp -d)
  fifo="$tempdir/fifo"
  mkfifo $fifo
  tmux popup -e parent_fiio=$fifo -E "echo \$(tty) >> \${parent_fiio} && $SHELL" &
  read -r popup_tty < $fifo
  dir=$(dirname $0)
  swapper="$dir/pattern_swap.sh"
  $swapper "^OPTION ttyname=.*" "OPTION ttyname=${popup_tty}" pinentry-curses "$@"
  exit
	;;
esac

exec pinentry-qt "$@"

