export MISE_TRUSTED_CONFIG_PATHS="$HOME/.config/mise/config.toml"

shell_base=$(basename $SHELL)
case "${shell_base}" in
*bash*)
  eval "$($HOME/.local/bin/mise activate bash)"
  ;;
*zsh*)
  eval "$($HOME/.local/bin/mise activate zsh)"
  ;;
esac

