export_unless_container_override MISE_GLOBAL_CONFIG_FILE "${XDG_CONFIG_HOME:-$HOME/.config}/mise/mise.toml"

if command -v mise > /dev/null 2>&1; then
  if [ -n "${ZSH_VERSION:-}" ]; then
    eval "$(mise activate zsh)"
  elif [ -n "${BASH_VERSION:-}" ]; then
    eval "$(mise activate bash)"
  fi
fi
