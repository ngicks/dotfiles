export_unless_container_override NPM_CONFIG_USERCONFIG "${XDG_CONFIG_HOME:-$HOME/.config}/npm/npmrc"
export_unless_container_override NPM_CONFIG_CACHE "${XDG_CACHE_HOME:-$HOME/.cache}/npm"
