# pim - pipe and vim. pipe stdin to tmpfile and open it with "${EDITOR:-${VISUAL:-vim}}"
pim() {
  local tmpfile
  tmpfile=$(mktemp "${TMPDIR:-/tmp}/pim.XXXXXX")

  cat > "$tmpfile"

  pushd "$(dirname "$tmpfile")" || return 1
  "${EDITOR:-${VISUAL:-vim}}" "$tmpfile"
  popd
}

devenv() {
  $HOME/.dotfiles/devenv_run.sh "$@"
}

devenv_prep() {
  $HOME/.dotfiles/devenv_prep.sh
}

gcd() {
  cd $(FZF_DEFAULT_COMMAND="fd --type d --hidden --no-ignore '^\.git\$' ${GITREPO_ROOT:-$HOME/gitrepo} --exec dirname {}" fzf --reverse)
}

# osc52copy - copy stdin to system clipboard via OSC52 escape sequence.
# Inside tmux, sends raw OSC52 so tmux's `set-clipboard on` can intercept it.
# Outside tmux, sends OSC52 directly to the terminal.
osc52copy() {
  local data
  data=$(cat)
  local encoded
  encoded=$(printf '%s' "$data" | base64 -w 0)

  local seq
  if [ -n "$TMUX" ]; then
    seq=$(printf '\033]52;c;%s\a' "$encoded")
    tmux set-buffer -- "$data"
  else
    seq=$(printf '\033]52;c;%s\a' "$encoded")
  fi

  printf '%s' "$seq" > /dev/tty
}
