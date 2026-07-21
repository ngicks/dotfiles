#!/usr/bin/env bash
set -euo pipefail

pane_id="${1:-${TMUX_PANE:-}}"
if [[ -z "${pane_id}" ]]; then
  echo "No pane id provided" >&2
  exit 1
fi

menu=()
n=1
while IFS=$'\t' read -r id label; do
  key=""
  if (( n <= 9 )); then
    key="${n}"
  fi
  menu+=("${label}" "${key}" "select-pane -t ${id}")
  n=$((n + 1))
done < <(tmux list-panes -t "${pane_id}" -f '#{pane_floating_flag}' \
  -F '#{pane_id}	#{?pane_active,*, }#{pane_index}: #{pane_current_command} #{pane_title}')

if (( ${#menu[@]} == 0 )); then
  tmux display-message "no floating panes in current window"
  exit 0
fi

tmux display-menu -T "Floating panes" "${menu[@]}"
