# Duplicated in env/02_editor.sh (zshenv) on purpose: see the note there.
# This zshrc-side copy re-evaluates after lazy home-manager activation has put
# nvim on PATH, which may not yet be the case when zshenv runs.
if (( $+commands[nvim] )); then
  export EDITOR="${commands[nvim]}"
  export VISUAL="${commands[nvim]}"
fi
