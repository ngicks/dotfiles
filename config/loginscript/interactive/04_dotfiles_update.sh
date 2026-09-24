# zsh/datetime and zsh/stat replace the date, uname and stat forks that ran on
# every login shell. zstat is loaded under its builtin name only, so it does
# not shadow an external `stat`.
zmodload zsh/datetime 2>/dev/null
zmodload -F zsh/stat b:zstat 2>/dev/null

dotfiles_should_update() {
  local MARKER_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/.update_daily"
  local NO_AUTO_UPDATE_MARKER_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/.no_update_daily"
  local INTERVAL=57600  # 16 hours in seconds

  if [[ -f "$NO_AUTO_UPDATE_MARKER_FILE" ]]; then
    return 1
  fi

  if [[ ! -f "$MARKER_FILE" ]]; then
    return 0
  fi

  local -a FILE_TIME
  if ! zstat -A FILE_TIME +mtime -- "$MARKER_FILE" 2>/dev/null; then
    FILE_TIME=(0)
  fi

  local TIME_DIFF=$((EPOCHSECONDS - FILE_TIME[1]))

  if [[ $TIME_DIFF -gt $INTERVAL ]]; then
    return 0
  else
    return 1
  fi
}

dotfiles_next_update_time() {
  local MARKER_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/.update_daily"
  local NO_AUTO_UPDATE_MARKER_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/.no_update_daily"
  local INTERVAL=57600  # 16 hours in seconds

  if [[ -f "$NO_AUTO_UPDATE_MARKER_FILE" ]]; then
    printf "never: no-auto-update marker found at ${NO_AUTO_UPDATE_MARKER_FILE}"
    return
  fi

  if [[ ! -f "$MARKER_FILE" ]]; then
    printf "now (marker file not found)"
    return
  fi

  local -a FILE_TIME
  if ! zstat -A FILE_TIME +mtime -- "$MARKER_FILE" 2>/dev/null; then
    FILE_TIME=(0)
  fi

  local NEXT_DATE
  strftime -s NEXT_DATE "%Y-%m-%d %H:%M:%S" $((FILE_TIME[1] + INTERVAL))

  printf "%s" "$NEXT_DATE"
}

if [[ -o login ]]; then
  if dotfiles_should_update; then
    if command -v dotfilesmgr > /dev/null 2>&1; then
      pushd "$HOME/.dotfiles" > /dev/null
      # Migrated from `deno task update:daily` to the moonbit CLI (managed
      # through mise). The command itself stamps the 16h-interval marker on
      # success. Concurrent logins are deduplicated inside the CLI via a file
      # lock (singleflight): one process updates, the rest wait for it and skip.
      dotfilesmgr standalone update-daily
      popd > /dev/null
    else
      # Don't touch the marker: keep warning every login until the daemon is installed.
      echo "dotfiles: dotfilesmgr not found on PATH; skipping daily update" >&2
    fi
  else
    echo "update deferred"
    echo "If you want update to happen again immediately, remove $HOME/.cache/dotfiles/.update_daily"
    echo ""
    printf "next update occurrs after "
    dotfiles_next_update_time
    echo
  fi
fi
