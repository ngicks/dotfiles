#!/usr/bin/env bash
# Merge settings.base.json into Claude Code's live settings.json
# ($CLAUDE_CONFIG_DIR/settings.json). Run manually. The live file is not
# symlinked into the repo: Claude Code rewrites it at runtime and everything
# outside the base section stays machine-local.

set -e

base="$(dirname "$0")/settings.base.json"
dir="${CLAUDE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/claude}"
live="$dir/settings.json"

mkdir -p "$dir"
[ -f "$live" ] || printf '{}\n' > "$live"

merged=$(jq -s '.[0] * .[1]' "$live" "$base")
printf '%s\n' "$merged" > "$live.tmp.$$"
mv "$live.tmp.$$" "$live"

echo "merged $base into $live"
