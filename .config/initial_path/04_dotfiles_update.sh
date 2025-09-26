#!/bin/bash
# Define function to check if dotfiles update should run
# This avoids unnecessary Deno startup overhead on every shell initialization

dotfiles_should_update() {
  local MARKER_FILE="$HOME/.cache/dotfiles/.update_daily"
  local INTERVAL=57600  # 16 hours in seconds

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