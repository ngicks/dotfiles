shell_base=$(basename $SHELL)
case "${shell_base}" in
*bash*)
  eval $(fzf --bash)
  ;;
*zsh*)
  eval $(fzf --zsh)
  ;;
esac

