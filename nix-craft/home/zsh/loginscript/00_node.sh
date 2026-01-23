export_unless_container_override NPM_CONFIG_DIR ${XDG_CONFIG_HOME:-$HOME/.config}/npm
export_unless_container_override NPM_CONFIG_GLOBALCONFIG ${NPM_CONFIG_DIR}/npmrc
