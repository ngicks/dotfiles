#!/usr/bin/env bash
set -e

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/mydotfiles/background-app"
COMMANDS_FILE="$CONFIG_DIR/commands.json"
SESSION_NAME="background-app"

# Use pickentry to select command with JSON callback for safe parsing
selected=$(pickentry --choices-file "$COMMANDS_FILE" --prompt "Run in background" --tmux --callback "echo '{{json .}}'")

# Exit if nothing selected (user cancelled)
[ -z "$selected" ] && exit 0

# Parse id and cmd from JSON using jq
id=$(echo "$selected" | jq -r '.id')
cmd=$(echo "$selected" | jq -r '.cmd')

# Run in tmux session background-app
# Split window creation and command execution so loginscripts are loaded first
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  # Create new detached session with window named after id
  tmux new-session -d -s "$SESSION_NAME" -n "$id"
  # Send the command to the session
  tmux send-keys -t "$SESSION_NAME:$id" "$cmd" Enter
  exit 0
fi

# Session exists - check if window with this id already exists
if tmux list-windows -t "$SESSION_NAME" -F '#W' | grep -qx "$id"; then
  # Window exists - rerun command in existing window
  tmux send-keys -t "$SESSION_NAME:$id" "$cmd" Enter
else
  # Create new window with title
  tmux new-window -t "$SESSION_NAME" -n "$id"
  tmux send-keys -t "$SESSION_NAME:$id" "$cmd" Enter
fi
