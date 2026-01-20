. ~/.config/tmux/color_scheme.sh

# display mode
STATUS_LEFT_MODE_VIEW="#[fg=${_tmux_color_text_light}#,bg=#5fab5b] VIEW "
STATUS_LEFT_MODE_COPY="#[fg=${_tmux_color_text_light}#,bg=#5b62ab] COPY "
STATUS_LEFT_MODE_SYNC="#[fg=${_tmux_color_text_light}#,bg=#2d259c] SYNC "

# prefix key is pressed or not
prefix_on_color="#[fg=${_tmux_color_text_dark}#,bg=${_tmux_color_5}]"
prefix_off_color="#[fg=${_tmux_color_text_dark}#,bg=${_tmux_color_4}]"
STATUS_LEFT_PREFIX="#{?client_prefix,${prefix_on_color} ON  ,${prefix_off_color} OFF }#[default]"

# display session
STATUS_LEFT_SESSION="#[fg=${_tmux_color_text_light}#, bg=${_tmux_color_1}] Session: #S #[default]"

STATUS_LEFT_VIEW=${STATUS_LEFT_MODE_VIEW}${STATUS_LEFT_PREFIX}${STATUS_LEFT_SESSION}
STATUS_LEFT_COPY=${STATUS_LEFT_MODE_COPY}${STATUS_LEFT_PREFIX}${STATUS_LEFT_SESSION}
STATUS_LEFT_SYNC=${STATUS_LEFT_MODE_SYNC}${STATUS_LEFT_PREFIX}${STATUS_LEFT_SESSION}

STATUS_LEFT="#{?pane_synchronized,${STATUS_LEFT_SYNC},#{?#{==:copy-mode,#{pane_mode}},${STATUS_LEFT_COPY},${STATUS_LEFT_VIEW}}}"

tmux set-option -g status-left-length 100
tmux set-option -g status-left "${STATUS_LEFT}"
