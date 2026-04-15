# no nested virtualization
if [ "${IN_CONTAINER:-0}" = "1" ]; then
  return 0
fi

# https://wiki.archlinux.org/title/GnuPG#SSH_agent

# Start gpg-agent if not already running
if ! pgrep -x -u "${USER}" gpg-agent &> /dev/null; then
  gpg-connect-agent /bye &> /dev/null
fi

# Additionally add:
# Set SSH to use gpg-agent (see 'man gpg-agent', section EXAMPLES)
unset SSH_AGENT_PID
if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne "$$" ]; then
  export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
fi

dbus-update-activation-environment --systemd SSH_AUTH_SOCK
