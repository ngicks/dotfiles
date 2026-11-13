#!/usr/bin/env bash

set -uo pipefail

# mise up and mise lock --bump write the lockfile only when every tool
# resolves, so a single failing tool (e.g. an npm trust downgrade) leaves all
# the others unlocked. Bumping one tool per invocation confines a failure to
# that tool.
failed=()

while IFS= read -r tool; do
  [ -n "$tool" ] || continue
  echo "lock --bump: $tool"
  if ! mise lock -g --bump "$tool"; then
    failed+=("$tool")
  fi
done < <(
  mise ls -J | jq -r '
    to_entries[]
    # Tools without a source are leftover installs no config requests.
    | select(any(.value[]; .source != null))
    | .key
  '
)

if [ "${#failed[@]}" -gt 0 ]; then
  echo ""
  echo "lock --bump failed for:"
  printf '  %s\n' "${failed[@]}"
  exit 1
fi
