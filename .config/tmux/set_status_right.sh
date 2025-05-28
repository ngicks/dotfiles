HOST_COLOR="$(uname -n | sha256sum | awk '{print substr($1, 1, 6)}')"

r=0x${HOST_COLOR:0:2}
g=0x${HOST_COLOR:2:2}
b=0x${HOST_COLOR:4:2}
brightness=$(((r*299 + g*587 + b*114)/1000))

HOST_FG_COLOR=#FFFFFF
if [ $brightness -gt 128 ]; then
  HOST_FG_COLOR=#000000
fi
HOST_BG_COLOR=$HOST_COLOR

tmux set-option -g status-right-length 100
tmux set-option -g status-right "#[fg=${HOST_FG_COLOR},bg=#${HOST_BG_COLOR}] #H #[fg=colour254,bg=colour241]| %Y-%m-%dT%H:%M:%S #[default]"
