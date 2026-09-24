# no nested virtualization
if [ "${IN_CONTAINER:-0}" = "1" ]; then
  return 0
fi

if [ -t 0 ]; then
  # Set GPG_TTY so gpg-agent knows where to prompt. See gpg-agent(1)
  # zsh's $TTY names the same terminal as tty(1) without the fork.
  export GPG_TTY="${TTY:-$(tty)}"
fi

# Function to recompute PINENTRY_USER_DATA on each prompt
# Enables correct pinentry context when attaching to tmux from different devices
__update_pinentry_user_data() {
  if [ "${HOMEENV_PREFER_TMUX_PINENTRY:-0}" != "1" ]; then
    return
  fi

  if [ -n "${TMUX}" ]; then
    # One tmux call for both fields: this runs before every prompt.
    local session_tty
    session_tty="$(tmux display -p '#S:#{client_tty}')"
    export PINENTRY_USER_DATA="TMUX_POPUP:${commands[tmux]}:${session_tty}:${TMUX}"
  elif [ -n "${ZELLIJ}" ]; then
    export PINENTRY_USER_DATA="ZELLIJ_POPUP:${commands[zellij]}:${ZELLIJ_SESSION_NAME}"
  fi
}

__update_pinentry_user_data

if [ "${HOMEENV_PREFER_TMUX_PINENTRY:-0}" -eq "1" ]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd __update_pinentry_user_data
fi

# Refresh gpg-agent tty in case user switches into an X session
# Backgrounded: it only notifies the agent and nothing here waits on it.
gpg-connect-agent updatestartuptty /bye > /dev/null 2>&1 < /dev/null &!
