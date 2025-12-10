. ~/.config/tmux/color_scheme.sh

tmux set-option -g status-bg "${_tmux_color_0}"
tmux set-option -g status-fg "colour255"
tmux setw -g window-status-format "| #I: #W |"
tmux setw -g window-status-current-format "#[fg=colour254,bg=${_tmux_color_2}]| #I: #W |"
