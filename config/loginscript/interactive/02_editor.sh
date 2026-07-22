# Duplicated in env/02_editor.sh (zshenv) on purpose: see the note there.
# This zshrc-side copy re-evaluates after lazy home-manager activation has put
# nvim on PATH, which may not yet be the case when zshenv runs.
if command -v nvim &> /dev/null; then
  export EDITOR="$(which nvim)"
  export VISUAL="$(which nvim)"
fi
