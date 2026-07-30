# Keep the uv cache in the shared gitrepo storage so it is reused across
# projects and devenv containers. uv's default link-mode on Linux is hardlink,
# which needs cache and venv on one filesystem; projects under gitrepo qualify.
# In containers run-devenv.sh overrides this with the mounted host path.
export_unless_container_override UV_CACHE_DIR "${GITREPO_ROOT:-$HOME/gitrepo}/__global_storage/uv/cache"
