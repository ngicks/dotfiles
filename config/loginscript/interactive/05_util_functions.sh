# pim - pipe and vim. pipe stdin to tmpfile and open it with "${EDITOR:-${VISUAL:-vim}}"
pim() {
  local tmpfile
  tmpfile=$(mktemp "${TMPDIR:-/tmp}/pim.XXXXXX")

  cat > "$tmpfile"

  pushd "$(dirname "$tmpfile")" || return 1
  "${EDITOR:-${VISUAL:-vim}}" "$tmpfile"
  popd
}

apm-bump() {
  if ! command -v git >/dev/null; then
    echo "apm-bump: git not found" >&2
    return 1
  fi

  # I have removed those dirs because apm
  # got confused and failed to edit settings.json, etc
  # Now I'm trying to let it handle that.
  # Turn on this line again if it's not capable
  # rm -rf ./.agents ./.claude ./.codex

  if [ ! -e ./.bare ]; then
    apm install --update -t codex,claude &&
      apm compile -t codex
    return $?
  fi

  # worktree base dir: sources resolve from the default-branch worktree,
  # outputs are written back here via --root.
  local branch wt
  branch=$(git --git-dir=.bare symbolic-ref --short HEAD 2>/dev/null || true)
  if [ -n "${branch}" ] && [ -d "./${branch}" ]; then
    wt=./${branch}
  elif [ -d ./main ]; then
    wt=./main
  elif [ -d ./master ]; then
    wt=./master
  else
    echo "apm-bump: no worktree dir found (tried '${branch:-<none>}', main, master)" >&2
    return 1
  fi
  (
    cd "${wt}" || exit 1
    apm install --update -t codex,claude --root .. &&
      cp ../apm.lock.yaml ./apm.lock.yaml &&
      cp ./apm.yml ../ &&
      cd .. &&
      apm compile -t codex
  )
}

devenv() {
  $HOME/.dotfiles/devenv_run.sh "$@"
}

devenv_prep() {
  $HOME/.dotfiles/devenv_prep.sh
}

gcd() {
  cd "$(crabswarm git list --full-path | fzf --query "${1:-}" --reverse)"
}

gcdw() {
  cd "$(crabswarm git list --full-path --worktree | fzf --query "${1:-}" --reverse)"
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
