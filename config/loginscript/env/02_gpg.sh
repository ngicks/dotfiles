# no nested virtualization
if [ "${IN_CONTAINER:-0}" = "1" ]; then
  return 0
fi

# https://wiki.archlinux.org/title/GnuPG#SSH_agent

# The slow path (pgrep, gpg-connect-agent, gpgconf and the dbus update) runs
# once per user session. Its result, the agent's ssh socket path, is cached
# under XDG_RUNTIME_DIR, which systemd clears together with the user manager
# that received the dbus update. A shell that finds the cached socket alive
# skips every fork. A missing socket means the agent is gone, so the slow path
# runs again and restarts it.
__gpg_cache="${XDG_RUNTIME_DIR:+${XDG_RUNTIME_DIR}/loginscript-gpg-ssh-socket}"
__gpg_sock=""
if [ -n "$__gpg_cache" ] && [ -r "$__gpg_cache" ]; then
  read -r __gpg_sock < "$__gpg_cache"
fi

if [ -n "$__gpg_sock" ] && [ -S "$__gpg_sock" ]; then
  unset SSH_AGENT_PID
  if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne "$$" ]; then
    export SSH_AUTH_SOCK="$__gpg_sock"
  fi
else
  # Start gpg-agent if not already running
  if ! pgrep -x -u "${USER}" gpg-agent &> /dev/null; then
    gpg-connect-agent /bye &> /dev/null
  fi

  # Additionally add:
  # Set SSH to use gpg-agent (see 'man gpg-agent', section EXAMPLES)
  unset SSH_AGENT_PID
  __gpg_sock="$(gpgconf --list-dirs agent-ssh-socket)"
  if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne "$$" ]; then
    export SSH_AUTH_SOCK="$__gpg_sock"
  fi

  if dbus-update-activation-environment --systemd SSH_AUTH_SOCK \
    && [ -n "$__gpg_cache" ] && [ -S "$__gpg_sock" ]; then
    printf '%s\n' "$__gpg_sock" > "$__gpg_cache" 2>/dev/null
  fi
fi
unset __gpg_cache __gpg_sock
