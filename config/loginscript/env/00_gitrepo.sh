# crabswarm manages the whole gitrepo tree (ghq-style clones plus the
# __global_storage package stores), so its resolved config is the source of
# truth for where that tree lives. Containers get GITREPO_ROOT handed in by
# run-devenv.sh (the host path, where the tree is mounted), and the guard also
# covers crabswarm being absent (e.g. before the first homeenv install).
if [[ -z "${GITREPO_ROOT:-}" ]]; then
  GITREPO_ROOT=$(crabswarm config --format '{{.GitRepoBaseDir}}' 2>/dev/null)
  export GITREPO_ROOT="${GITREPO_ROOT:-$HOME/gitrepo}"
fi
