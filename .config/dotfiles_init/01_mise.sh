if [[ "$IN_CONTAINER" -ne "1" ]]; then
  export MISE_TRUSTED_CONFIG_PATHS="${XDG_CONFIG_HOME:-$HOME/.config}/mise/mise.toml"
  export MISE_GLOBAL_CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/mise/mise.toml"
fi

shell_base=$(basename $SHELL)
case "${shell_base}" in
*bash*)
  eval "$($HOME/.local/bin/mise activate bash)"
  ;;
*zsh*)
  eval "$($HOME/.local/bin/mise activate zsh)"
  ;;
esac

