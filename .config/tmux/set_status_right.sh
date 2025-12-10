. ~/.config/tmux/color_scheme.sh

tmux set-option -g status-right-length 100

zoom_on_color="#[fg=${_tmux_color_text_dark}#,bg=${_tmux_color_5}]"
zoom_off_color="#[fg=${_tmux_color_text_dark}#,bg=${_tmux_color_4}]"

STATUS_RIGHT_ZOOM_FLAG="#{?window_zoomed_flag,${zoom_on_color}[Zoomed],${zoom_off_color}[normal]}#[default]"
STATUS_RIGHT_TIMER="#[fg=${_tmux_color_text_light},bg=${_tmux_color_1}] %Y-%m-%dT%H:%M:%S #[default]"

STATUS_RIGHT="${STATUS_RIGHT_ZOOM_FLAG}${STATUS_RIGHT_TIMER}"

tmux set-option -g status-right "${STATUS_RIGHT}"
