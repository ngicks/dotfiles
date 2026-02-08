#!/usr/bin/env bash
# rg-front-matter: Extract YAML front matter from markdown files.
# Designed as an `rg --pre` preprocessor.
#
# Usage: rg-front-matter <filepath>
#        rg --pre rg-front-matter --pre-glob '*.md' "pattern" ./dir/
#
# Supports RG_FRONT_MATTER_FIELDS env var to filter to specific YAML keys.
# Example: RG_FRONT_MATTER_FIELDS=tags,created rg --pre rg-front-matter ...

set -euo pipefail

if [[ $# -lt 1 ]]; then
  exit 0
fi

file="$1"

if [[ ! -f "$file" ]]; then
  exit 0
fi

# Parse fields from environment variable
IFS=',' read -ra fields <<< "${RG_FRONT_MATTER_FIELDS:-}"

awk -v fields_str="${RG_FRONT_MATTER_FIELDS:-}" '
BEGIN {
  in_fm = 0
  started = 0
  n_fields = 0
  if (fields_str != "") {
    n_fields = split(fields_str, fields_arr, ",")
    for (i = 1; i <= n_fields; i++) {
      gsub(/^[ \t]+|[ \t]+$/, "", fields_arr[i])
      wanted[fields_arr[i]] = 1
    }
  }
}
/^---[[:space:]]*$/ {
  if (!started) {
    started = 1
    in_fm = 1
    next
  } else if (in_fm) {
    exit
  }
}
in_fm {
  if (n_fields == 0) {
    print
  } else {
    # Extract key before colon
    idx = index($0, ":")
    if (idx > 0) {
      key = substr($0, 1, idx - 1)
      gsub(/^[ \t]+|[ \t]+$/, "", key)
      if (key in wanted) {
        print
      }
    }
  }
}
' "$file"
