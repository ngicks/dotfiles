# display mode
STATUS_LEFT_MODE_VIEW="#[fg=colour254,bg=colour2] VIEW "
STATUS_LEFT_MODE_COPY="#[fg=colour254,bg=colour24] COPY "

# prefix key is pressed or not
prefix_on_color="#[fg=colour254#,bg=colour127]"
prefix_off_color="#[fg=colour254#,bg=colour53]"
STATUS_LEFT_PREFIX="#{?client_prefix,${prefix_on_color} ON  ,${prefix_off_color} OFF }#[default]"

# display session
STATUS_LEFT_SESSION="#[fg=colour254, bg=colour241] Session: #S #[default]"

STATUS_LEFT_VIEW=${STATUS_LEFT_MODE_VIEW}${STATUS_LEFT_PREFIX}${STATUS_LEFT_SESSION}
STATUS_LEFT_COPY=${STATUS_LEFT_MODE_COPY}${STATUS_LEFT_PREFIX}${STATUS_LEFT_SESSION}

tmux set-option -g status-left "${STATUS_LEFT_VIEW}"
tmux set-hook -g pane-mode-changed "if -F \"#{m/r:(copy|view)-mode,#{pane_mode}}\"\
  \"set-option -g status-left \\\"${STATUS_LEFT_COPY}\\\"\"\
  \"set-option -g status-left \\\"${STATUS_LEFT_VIEW}\\\"\"\
"
