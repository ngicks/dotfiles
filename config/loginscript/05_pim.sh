#!/bin/bash
# pim - Pipe stdin to temp file, cd there, and edit

pim() {
  # Create temp file
  local tmpfile
  tmpfile=$(mktemp "${TMPDIR:-/tmp}/pim.XXXXXX")

  # Read stdin into temp file
  cat > "$tmpfile"

  # Change to temp file's directory
  cd "$(dirname "$tmpfile")" || return 1

  # Open in editor (priority: EDITOR > VISUAL > vim)
  "${EDITOR:-${VISUAL:-vim}}" "$tmpfile"
}
