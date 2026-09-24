if [[ -z "${ZSH_NAME:-}" ]]; then
  return 0
fi

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

# `zoxide init zsh` prints the same script for a given binary, so it is cached
# under the binary's resolved path: a nix store or mise install path changes
# on upgrade and invalidates the cache even though nix store files carry a
# 1970 mtime. The mtime check covers binaries replaced in place, such as
# distro packages. Sourced at top level because the script assigns globals
# such as precmd_functions.
__zoxide_bin="${commands[zoxide]:A}"
if [[ -n "$__zoxide_bin" ]]; then
  __zoxide_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zoxide-init/${__zoxide_bin//\//%}.zsh"
  if [[ ! -r "$__zoxide_cache" || "$__zoxide_bin" -nt "$__zoxide_cache" ]]; then
    mkdir -p "${__zoxide_cache:h}" 2>/dev/null
    rm -f "${__zoxide_cache:h}"/*.zsh(N) 2>/dev/null
    if ! "$__zoxide_bin" init zsh >| "$__zoxide_cache.$$" 2>/dev/null \
      || ! mv -f "$__zoxide_cache.$$" "$__zoxide_cache" 2>/dev/null; then
      rm -f "$__zoxide_cache.$$" 2>/dev/null
      __zoxide_cache=
    fi
  fi
  if [[ -n "$__zoxide_cache" ]]; then
    . "$__zoxide_cache"
  else
    eval "$(zoxide init zsh)"
  fi
fi
unset __zoxide_bin __zoxide_cache

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
