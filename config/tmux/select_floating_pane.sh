#!/usr/bin/env bash
set -euo pipefail

pane_id="${1:-${TMUX_PANE:-}}"
if [[ -z "${pane_id}" ]]; then
  echo "No pane id provided" >&2
  exit 1
fi

# prefer the last (previously active) tiled pane, else the first tiled pane
back_target="$(tmux list-panes -t "${pane_id}" \
  -f '#{&&:#{!:#{pane_floating_flag}},#{pane_last}}' -F '#{pane_id}' | head -n1)"
if [[ -z "${back_target}" ]]; then
  back_target="$(tmux list-panes -t "${pane_id}" \
    -f '#{!:#{pane_floating_flag}}' -F '#{pane_id}' | head -n1)"
fi

menu=()
if [[ -n "${back_target}" ]]; then
  menu+=("back to tiled" "t" "select-pane -t ${back_target}")
  # a lone empty item is a separator line
  menu+=("")
fi
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

if (( n == 1 )); then
  tmux display-message "no floating panes in current window"
  exit 0
fi

tmux display-menu -T "Floating panes" "${menu[@]}"
