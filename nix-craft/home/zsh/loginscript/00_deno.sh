export DENO_NO_UPDATE_CHECK=1
export DENO_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/deno/cache"
# not documented but deno actually makes bin dir under DENO_INSTALL_ROOT.
export DENO_INSTALL_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/deno"
