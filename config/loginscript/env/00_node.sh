export_unless_container_override NPM_CONFIG_USERCONFIG "${XDG_CONFIG_HOME:-$HOME/.config}/npm/npmrc"
export_unless_container_override NPM_CONFIG_CACHE "${XDG_CACHE_HOME:-$HOME/.cache}/npm"

# Keep the pnpm content-addressable store in the shared gitrepo storage so it is
# reused across projects and devenv containers. pnpm appends the store-layout
# version (e.g. v11) under this dir itself, making the real store .../store/v11.
# In containers run-devenv.sh overrides this with the mounted host path.
export_unless_container_override pnpm_config_store_dir "${GITREPO_ROOT:-$HOME/gitrepo}/__global_storage/pnpm/store"
