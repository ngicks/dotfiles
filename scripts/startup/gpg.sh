if [ -t 0 ]; then
	# Set GPG_TTY so gpg-agent knows where to prompt.  See gpg-agent(1)
	export GPG_TTY="$(tty)"
fi

# but in tmux use tmux display-pop and pientry-curses
if [ -n "${TMUX}" ]; then
  export PINENTRY_USER_DATA="TMUX_POPUP:$(which tmux):${TMUX}"
elif [ -n "${ZELLIJ}" ]; then
  export PINENTRY_USER_DATA="ZELLIJ_POPUP:$(which zellij):${ZELLIJ_SESSION_NAME}"
fi

# https://wiki.archlinux.org/title/GnuPG#SSH_agent

# Start gpg-agent if not already running
if ! pgrep -x -u "${USER}" gpg-agent &> /dev/null; then
  gpg-connect-agent /bye &> /dev/null
fi

# Additionally add:
# Set SSH to use gpg-agent (see 'man gpg-agent', section EXAMPLES)
unset SSH_AGENT_PID
if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
  # export SSH_AUTH_SOCK="/run/user/$UID/gnupg/S.gpg-agent.ssh"
  export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
fi

# Refresh gpg-agent tty in case user switches into an X session
gpg-connect-agent updatestartuptty /bye > /dev/null

dbus-update-activation-environment --systemd SSH_AUTH_SOCK
