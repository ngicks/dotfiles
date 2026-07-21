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

# tmux >= 3.7 has floating panes (new-pane); older versions fall back to a window
tmux_version="$(tmux display-message -p '#{version}')"
version_num="${tmux_version#next-}"
major="${version_num%%.*}"
minor="${version_num#*.}"
minor="${minor%%[^0-9]*}"
use_floating=0
if [[ "${major}" =~ ^[0-9]+$ && "${minor}" =~ ^[0-9]+$ ]] \
  && (( major > 3 || (major == 3 && minor >= 7) )); then
  use_floating=1
fi

if (( use_floating )); then
  # size must be given at creation via -x/-y (undocumented in the 3.7b man
  # page); resize-pane on a floating pane corrupts the layout underneath in
  # 3.7b (fixed on master by layout_resize_floating_pane_to)
  tmux new-pane -c "${pane_cwd}" -x 90% -y 80% -X 5% -Y 5% \
    "sh -c '${editor_cmd_str:1}; rm -f ${scrollback_file}' --"
else
  tmux new-window -n "scrollback" -c "${pane_cwd}" "sh -c '${editor_cmd_str:1}; rm -f ${scrollback_file}' --"
fi

# return pane to normal mode if we were in copy mode when launching popup
if [[ "${initial_mode}" =~ ^copy-mode ]]; then
  tmux send-keys -t "${pane_id}" -X cancel
fi
