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

  local CURRENT_TIME
  CURRENT_TIME=$(date +%s)

  local FILE_TIME
  case "$(uname -s)" in
    Linux*)
      FILE_TIME=$(stat -c %Y "$MARKER_FILE" 2>/dev/null || echo 0)
      ;;
    Darwin*)
      FILE_TIME=$(stat -f %m "$MARKER_FILE" 2>/dev/null || echo 0)
      ;;
    *)
      return 0
      ;;
  esac

  local TIME_DIFF=$((CURRENT_TIME - FILE_TIME))

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

  local FILE_TIME
  case "$(uname -s)" in
    Linux*)
      FILE_TIME=$(stat -c %Y "$MARKER_FILE" 2>/dev/null || echo 0)
      ;;
    Darwin*)
      FILE_TIME=$(stat -f %m "$MARKER_FILE" 2>/dev/null || echo 0)
      ;;
    *)
      printf "unknown (unsupported OS)"
      return
      ;;
  esac

  local NEXT_TIME=$((FILE_TIME + INTERVAL))
  local NEXT_DATE

  case "$(uname -s)" in
    Linux*)
      NEXT_DATE=$(date -d "@$NEXT_TIME" "+%Y-%m-%d %H:%M:%S")
      ;;
    Darwin*)
      NEXT_DATE=$(date -r "$NEXT_TIME" "+%Y-%m-%d %H:%M:%S")
      ;;
  esac

  printf "%s" "$NEXT_DATE"
}

if [[ -o login ]]; then
  if dotfiles_should_update; then
    pushd "$HOME/.dotfiles" > /dev/null
    deno task update:daily > /dev/null
    popd > /dev/null
  else
    echo "update deferred"
    echo "If you want update to happen again immediately, remove $HOME/.cache/dotfiles/.update_daily"
    echo ""
    echo "next update occurrs after $(dotfiles_next_update_time)"
  fi
fi
