# Keep the uv cache in the shared gitrepo storage so it is reused across
# projects and devenv containers. uv's default link-mode on Linux is hardlink,
# which needs cache and venv on one filesystem; projects under gitrepo qualify.
# In containers run-devenv.sh overrides this with the mounted host path.
export_unless_container_override UV_CACHE_DIR "${GITREPO_ROOT:-$HOME/gitrepo}/__global_storage/uv/cache"
# Never let uv fall back to the nix profile python: a venv built on it records
# home=<profile>/bin (/home/<user>/.nix-profile on the host, /root/.nix-profile
# in the container), so the venv only works on the side that created it.
# Managed pythons live under the uv data dir, which the container mounts at its
# host path, so venvs built on them resolve on both sides.
export_unless_container_override UV_PYTHON_PREFERENCE only-managed
