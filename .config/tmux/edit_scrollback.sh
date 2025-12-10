#!/bin/bash
set -euo pipefail

pane_id="${1:-${TMUX_PANE:-}}"
if [[ -z "${pane_id}" ]]; then
  echo "No pane id provided" >&2
  exit 1
fi

c_opt=""
if [[ ! -z "${2:-}" ]]; then
  c_opt="-c ${2}"
fi

scrollback_file="$(mktemp -t tmux-scrollback.XXXXXX)"
trap 'rm -f "${scrollback_file}"' EXIT

tmux capture-pane -p -J -S -32768 -t "${pane_id}" >"${scrollback_file}"

editor="${EDITOR:-${VISUAL:-vi}}"
tmux display-popup -w 90% -h 90% $c_opt -E "sh -c '\"${editor}\" \"${scrollback_file}\"' --"
