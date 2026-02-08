#!/usr/bin/env bash
# rg --pre script: extracts only YAML frontmatter (between --- delimiters) from markdown files.
# Usage: rg --pre ./agents/skills/persistent-memory/frontmatter-pre.sh ...
set -euo pipefail
awk 'NR==1 && /^---$/{p=1; next} p && /^---$/{exit} p' "$1"
