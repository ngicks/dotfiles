. ~/.config/tmux/color_scheme.sh

zoom_on_color="#[fg=${_tmux_color_text_dark}#,bg=${_tmux_color_5}]"
z_flag="#{?window_zoomed_flag,${zoom_on_color}[Z],}#[fg=colour254,bg=${_tmux_color_2}]"

tmux set-option -g status-bg "${_tmux_color_0}"
tmux set-option -g status-fg "colour255"
tmux setw -g window-status-format "| #I: #W |"
tmux setw -g window-status-current-format "#[fg=colour254,bg=${_tmux_color_2}]| #I: #W ${z_flag}|"
