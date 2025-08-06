if [ -t 0 ]; then
	# Set GPG_TTY so gpg-agent knows where to prompt.  See gpg-agent(1)
	export GPG_TTY="$(tty)"
fi

# but in tmux use tmux display-pop and pientry-curses
if [ -n "${TMUX}" ]; then
  export PINENTRY_USER_DATA=TMUX_POPUP
fi
