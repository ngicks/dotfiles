export DENO_NO_UPDATE_CHECK=1
export_unless_container_override DENO_DIR "${XDG_DATA_HOME:-$HOME/.local/share}/deno/cache"
# not documented but deno actually makes bin dir under DENO_INSTALL_ROOT.
export_unless_container_override DENO_INSTALL_ROOT "${XDG_DATA_HOME:-$HOME/.local/share}/deno"
