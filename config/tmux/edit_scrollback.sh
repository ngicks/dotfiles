#!/usr/bin/env bash
set -euo pipefail

pane_id="${1:-${TMUX_PANE:-}}"
if [[ -z "${pane_id}" ]]; then
  echo "No pane id provided" >&2
  exit 1
fi
initial_mode="$(tmux display-message -p -t "${pane_id}" '#{pane_mode}')"

pane_cwd="$(tmux display-message -p -t "${pane_id}" '#{pane_current_path}')"

scrollback_file="$(mktemp -t tmux-scrollback.XXXXXX)"

tmux capture-pane -p -J -S -32768 -t "${pane_id}" > "${scrollback_file}"

editor="${EDITOR:-${VISUAL:-vi}}"
line_count=$(wc -l < "${scrollback_file}")
if [[ "${line_count}" -eq 0 ]]; then
  line_count=1
fi

read -r -a editor_cmd <<< "${editor}"
line_arg=""
case "$(basename "${editor_cmd[0]}")" in
  vi|vim|nvim) line_arg="+${line_count}" ;;
  nano) line_arg="+${line_count},1" ;;
esac
if [[ -n "${line_arg}" ]]; then
  editor_cmd+=("${line_arg}")
fi
editor_cmd+=("${scrollback_file}")
printf -v editor_cmd_str ' %q' "${editor_cmd[@]}"

tmux new-window -n "scrollback" -c "${pane_cwd}" "sh -c '${editor_cmd_str:1}; rm -f ${scrollback_file}' --"

# return pane to normal mode if we were in copy mode when launching popup
if [[ "${initial_mode}" =~ ^copy-mode ]]; then
  tmux send-keys -t "${pane_id}" -X cancel
fi
