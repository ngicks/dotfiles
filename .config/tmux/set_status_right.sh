. ~/.config/tmux/color_scheme.sh

tmux set-option -g status-right-length 100
tmux set-option -g status-right "#[fg=${_tmux_color_text_light},bg=${_tmux_color_1}] %Y-%m-%dT%H:%M:%S #[default]"
