# pim - pipe and vim. pipe stdin to tmpfile and open it with "${EDITOR:-${VISUAL:-vim}}"
pim() {
  # Create temp file
  local tmpfile
  tmpfile=$(mktemp "${TMPDIR:-/tmp}/pim.XXXXXX")

  # Read stdin into temp file
  cat > "$tmpfile"

  # Change to temp file's directory
  pushd "$(dirname "$tmpfile")" || return 1

  # Open in editor (priority: EDITOR > VISUAL > vim)
  "${EDITOR:-${VISUAL:-vim}}" "$tmpfile"

  popd
}

devenv() {
  $HOME/.dotfiles/devenv_run.sh "$@"
}

gcd() {
  cd $(FZF_DEFAULT_COMMAND="fd --type d --hidden --no-ignore '^\.git\$' ${GITREPO_ROOT:-$HOME/gitrepo} --exec dirname {}" fzf --reverse)
}
