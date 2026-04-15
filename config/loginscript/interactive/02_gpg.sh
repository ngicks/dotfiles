# no nested virtualization
if [ "${IN_CONTAINER:-0}" = "1" ]; then
  return 0
fi

if [ -t 0 ]; then
  # Set GPG_TTY so gpg-agent knows where to prompt. See gpg-agent(1)
  export GPG_TTY="$(tty)"
fi

# Function to recompute PINENTRY_USER_DATA on each prompt
# Enables correct pinentry context when attaching to tmux from different devices
__update_pinentry_user_data() {
  if [ "${HOMEENV_PREFER_TMUX_PINENTRY:-0}" != "1" ]; then
    return
  fi

  if [ -n "${TMUX}" ]; then
    export PINENTRY_USER_DATA="TMUX_POPUP:$(which tmux):$(tmux display -p '#S'):$(tmux display -p '#{client_tty}'):${TMUX}"
  elif [ -n "${ZELLIJ}" ]; then
    export PINENTRY_USER_DATA="ZELLIJ_POPUP:$(which zellij):${ZELLIJ_SESSION_NAME}"
  fi
}

__update_pinentry_user_data

if [ "${HOMEENV_PREFER_TMUX_PINENTRY:-0}" -eq "1" ]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd __update_pinentry_user_data
fi

# Refresh gpg-agent tty in case user switches into an X session
gpg-connect-agent updatestartuptty /bye > /dev/null
