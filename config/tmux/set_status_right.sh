. ~/.config/tmux/color_scheme.sh

tmux set-option -g status-right-length 100

STATUS_RIGHT_TIMER="#[fg=${_tmux_color_text_light},bg=${_tmux_color_1}] %Y-%m-%dT%H:%M:%S #[default]"

STATUS_RIGHT="${STATUS_RIGHT_TIMER}"

tmux set-option -g status-right "${STATUS_RIGHT}"
