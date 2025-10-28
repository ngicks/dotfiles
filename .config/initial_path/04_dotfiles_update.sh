#!/bin/bash
# Define function to check if dotfiles update should run
# This avoids unnecessary Deno startup overhead on every shell initialization

dotfiles_should_update() {
  local MARKER_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/.update_daily"
  local NO_AUTO_UPDATE_MARKER_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/.no_update_daily"
  local INTERVAL=57600  # 16 hours in seconds

  if [[ -f "$NO_AUTO_UPDATE_MARKER_FILE" ]]; then
    return 1
  fi

  # If marker file doesn't exist, update is needed
  if [[ ! -f "$MARKER_FILE" ]]; then
    return 0
  fi

  # Get current time
  local CURRENT_TIME=$(date +%s)

  # Handle OS-specific stat command to get file modification time
  local FILE_TIME
  case "$(uname -s)" in
    Linux*)
      FILE_TIME=$(stat -c %Y "$MARKER_FILE" 2>/dev/null || echo 0)
      ;;
    Darwin*)
      FILE_TIME=$(stat -f %m "$MARKER_FILE" 2>/dev/null || echo 0)
      ;;
    *)
      # Unknown OS, run update to be safe
      return 0
      ;;
  esac

  # Calculate time difference
  local TIME_DIFF=$((CURRENT_TIME - FILE_TIME))

  # Return 0 (true) if interval has passed, 1 (false) otherwise
  if [[ $TIME_DIFF -gt $INTERVAL ]]; then
    return 0
  else
    return 1
  fi
}

# Function to get next update time (returns string)
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

  # Handle OS-specific stat command to get file modification time
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

  # Calculate next update time
  local NEXT_TIME=$((FILE_TIME + INTERVAL))

  # Format and return the next update time
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
