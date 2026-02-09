__update_pane_title() {
  printf '\033]2;%s\033\\' "$(uname -n)"
}

if [[ -z ${NVIM:-} ]]; then
  if [[ -n "${ZSH_NAME:-}" ]]; then
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd __update_pane_title
  elif [[ -n "${BASH_VERSION:-}" ]]; then
    safe_hook_append precmd_functions __update_pane_title
  fi
fi
