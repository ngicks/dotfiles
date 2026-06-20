# Keep apm's (agent package manager) cache in the shared gitrepo storage so
# downloaded packages are reused across projects and devenv containers. In
# containers devenv/scripts/opts.d/45-apm.sh forwards this same path.
export_unless_container_override APM_CACHE_DIR "${GITREPO_ROOT:-$HOME/gitrepo}/__global_storage/apm/cache"
