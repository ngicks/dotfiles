# Duplicated in interactive/02_editor.sh on purpose:
# - Here (zshenv): apps in the devenv container are started via `zsh -lc "command"`,
#   which never sources zshrc, so they only see VISUAL/EDITOR if exported here.
# - There (zshrc): on interactive shell sessions home-manager activation is lazy,
#   so eagerly evaluating nvim's path here can fail; the interactive script
#   re-evaluates once nvim is actually on PATH.
if command -v nvim &> /dev/null; then
  export EDITOR="$(which nvim)"
  export VISUAL="$(which nvim)"
fi
