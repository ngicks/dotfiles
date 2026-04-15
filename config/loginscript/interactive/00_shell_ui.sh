bindkey -e
bindkey '^[[1;5D' backward-word  # Ctrl+Left
bindkey '^[[1;5C' forward-word   # Ctrl+Right
# missing in devenv container
bindkey '^[[3~' delete-char      # Delete key

function fzf-select-history() {
  BUFFER=$(history -n -r 1 | fzf --query "$LBUFFER" --reverse)
  CURSOR=$#BUFFER
  zle reset-prompt
}
zle -N fzf-select-history
bindkey '^r' fzf-select-history

eval "$(zoxide init zsh)"

function fzf-zoxide() {
  local selected_dir=$(zoxide query --list | fzf --reverse)
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N fzf-zoxide
setopt noflowcontrol
bindkey '^q' fzf-zoxide
