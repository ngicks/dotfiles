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
  # Strip any inherited shims entry before appending: in a nested
  # shell, hook-env re-inserts install paths after inherited entries
  # it doesn't manage, which would otherwise leave shims in front of
  # them, shadowing the real install paths.
  _mise_shims="${MISE_SHIMS_DIR:-${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims}"
  _mise_new_path=""
  _mise_rest="${PATH}:"
  while [ -n "$_mise_rest" ]; do
    _mise_p="${_mise_rest%%:*}"
    _mise_rest="${_mise_rest#*:}"
    if [ -z "$_mise_p" ] || [ "$_mise_p" = "$_mise_shims" ]; then
      continue
    fi
    _mise_new_path="${_mise_new_path:+${_mise_new_path}:}${_mise_p}"
  done
  export PATH="${_mise_new_path}:${_mise_shims}"
  unset _mise_shims _mise_new_path _mise_rest _mise_p
fi
