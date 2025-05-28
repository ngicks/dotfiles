# display mode
STATUS_LEFT_MODE_VIEW="#[fg=#cdeccd,bg=#5fab5b] VIEW "
STATUS_LEFT_MODE_COPY="#[fg=#bdc1ee,bg=#5b62ab] COPY "

# prefix key is pressed or not
prefix_on_color="#[fg=colour254#,bg=colour127]"
prefix_off_color="#[fg=colour254#,bg=colour53]"
STATUS_LEFT_PREFIX="#{?client_prefix,${prefix_on_color} ON  ,${prefix_off_color} OFF }#[default]"

# display session
STATUS_LEFT_SESSION="#[fg=colour254, bg=colour241] Session: #S #[default]"

STATUS_LEFT_VIEW=${STATUS_LEFT_MODE_VIEW}${STATUS_LEFT_PREFIX}${STATUS_LEFT_SESSION}
STATUS_LEFT_COPY=${STATUS_LEFT_MODE_COPY}${STATUS_LEFT_PREFIX}${STATUS_LEFT_SESSION}


STATUS_LEFT="if -F \"#{m/r:copy-mode,#{pane_mode}}\"\
  \"set-option -p status-left \\\"${STATUS_LEFT_COPY}\\\"\"\
  \"set-option -p status-left \\\"${STATUS_LEFT_VIEW}\\\"\"\
"

tmux set-option -g status-left "${STATUS_LEFT}"
tmux set-hook -g session-changed "${STATUS_LEFT}"
tmux set-hook -g session-window-changed "${STATUS_LEFT}"
tmux set-hook -g window-pane-changed "${STATUS_LEFT}"
tmux set-hook -g pane-mode-changed "${STATUS_LEFT}"
