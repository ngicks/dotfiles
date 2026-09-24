# Duplicated in interactive/02_editor.sh on purpose:
# - Here (zshenv): apps in the devenv container are started via `zsh -lc "command"`,
#   which never sources zshrc, so they only see VISUAL/EDITOR if exported here.
# - There (zshrc): on interactive shell sessions home-manager activation is lazy,
#   so eagerly evaluating nvim's path here can fail; the interactive script
#   re-evaluates once nvim is actually on PATH.
if [ -n "${ZSH_VERSION:-}" ]; then
  # $commands looks the path up without the fork of a command substitution.
  _nvim_path="${commands[nvim]-}"
else
  _nvim_path="$(command -v nvim 2>/dev/null)"
fi
if [ -n "$_nvim_path" ]; then
  export EDITOR="$_nvim_path"
  export VISUAL="$_nvim_path"
fi
unset _nvim_path
