__update_pane_title() {
  printf '\033]2;%s\033\\' "$(uname -n)"
}

if [[ -z ${NVIM:-} ]]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd __update_pane_title
fi
