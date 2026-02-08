#!/usr/bin/env bash
# Skim all persistent-memory files by showing the first 9 lines (frontmatter + heading) of each.
# Usage: ./agents/skills/persistent-memory/skim-memories.sh [keyword ...]

set -euo pipefail

# Resolve project root: try git, then walk up looking for .claude/ or AGENTS.md
find_project_root() {
  local root
  root="$(git rev-parse --show-toplevel 2>/dev/null)" && { echo "$root"; return; }

  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/.claude" || -f "$dir/AGENTS.md" ]]; then
      echo "$dir"
      return
    fi
    dir="$(dirname "$dir")"
  done
  echo "."
}

REPO_ROOT="$(find_project_root)"
MEMORIES_DIR="$REPO_ROOT/.claude/skills/persistent-memory/memories"

if [[ ! -d "$MEMORIES_DIR" ]]; then
  echo "No memories directory found at $MEMORIES_DIR"
  exit 0
fi

find_cmd() {
  if command -v fd &>/dev/null; then
    fd -e md . "$MEMORIES_DIR" --no-ignore --hidden
  else
    find "$MEMORIES_DIR" -name '*.md' -type f
  fi
}

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
PRE="$SKILL_DIR/print-frontmatter.sh"

if [[ $# -gt 0 ]]; then
  # Build a regex pattern that matches any of the keywords
  pattern="$(IFS="|"; echo "$*")"
  # Filter to files whose frontmatter matches any keyword, then skim each
  rg -l -i --no-ignore --hidden --pre "$PRE" "$pattern" "$MEMORIES_DIR" 2>/dev/null | while IFS= read -r file; do
    echo "=== $file ==="
    $PRE "$file"
    echo
  done
else
  # Skim every memory file
  find_cmd | sort | while IFS= read -r file; do
    echo "=== $file ==="
    $PRE "$file"
    echo
  done
fi
