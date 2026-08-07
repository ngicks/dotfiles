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
  # Adds shims as fallback.
  # Not using `mise activate --shims`: it prepends, shadowing the
  # real install paths hook-env injects. Append at tail instead so
  # shims only resolve when the real path is gone.
  _mise_shims="${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims"
  case ":$PATH:" in
    *":${_mise_shims}:"*)
      ;;
    *)
      export PATH="${PATH}:${_mise_shims}"
      ;;
  esac
  unset _mise_shims
fi
