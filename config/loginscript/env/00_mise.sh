export_unless_container_override MISE_GLOBAL_CONFIG_FILE "${XDG_CONFIG_HOME:-$HOME/.config}/mise/mise.toml"

if [ "${IN_CONTAINER:-}" = "1" ] && [ -n "${ADDITIONAL_MISE_TRUSTED_CONFIG_PATHS:-}" ]; then
    _mise_trust_rest="${ADDITIONAL_MISE_TRUSTED_CONFIG_PATHS}:"
    while [ -n "$_mise_trust_rest" ]; do
        _mise_trust_path="${_mise_trust_rest%%:*}"
        _mise_trust_rest="${_mise_trust_rest#*:}"
        [ -z "$_mise_trust_path" ] && continue
        case ":${MISE_TRUSTED_CONFIG_PATHS:-}:" in
            *:"$_mise_trust_path":*)
                ;;
            *)
                export MISE_TRUSTED_CONFIG_PATHS="${MISE_TRUSTED_CONFIG_PATHS:+${MISE_TRUSTED_CONFIG_PATHS}:}${_mise_trust_path}"
                ;;
        esac
    done
    unset _mise_trust_rest _mise_trust_path
fi

if command -v mise > /dev/null 2>&1; then
  if [ -n "${ZSH_VERSION:-}" ]; then
    eval "$(mise activate zsh)"
  elif [ -n "${BASH_VERSION:-}" ]; then
    eval "$(mise activate bash)"
  fi

  # `mise up` and `mise prune` breaks PATH for
  # long-lived apps
  # Adds shims as fallback
  eval "$(mise activate --shims)"
fi
