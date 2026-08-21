# Keep playwright's downloaded browsers in the shared gitrepo storage so they
# are reused across projects and devenv containers. `playwright install`
# creates the directory itself. In containers run-devenv.sh overrides this
# with the mounted host path.
export_unless_container_override PLAYWRIGHT_BROWSERS_PATH "${GITREPO_ROOT:-$HOME/gitrepo}/__global_storage/playwright/browsers"
