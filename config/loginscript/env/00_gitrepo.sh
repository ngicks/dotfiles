# crabswarm manages the whole gitrepo tree (ghq-style clones plus the
# __global_storage package stores), so its resolved config is the source of
# truth for where that tree lives. Containers get GITREPO_ROOT handed in by
# run-devenv.sh (the host path, where the tree is mounted), and the guard also
# covers crabswarm being absent (e.g. before the first homeenv install).
if [[ -z "${GITREPO_ROOT:-}" ]]; then
  if [ -n "${ZSH_VERSION:-}" ] && (( $+commands[crabswarm] )); then
    # `crabswarm config` is a Go binary fork on every login shell, so its
    # answer is cached under a key built from everything it reads for this
    # value: the binary, the config file (path and mtime; a home-manager
    # switch changes the nix store path it links to), the env overrides and
    # $HOME for the default. The config path follows crabswarm's own lookup:
    # $CRABSWARM_CONF, else os.UserConfigDir()/crabswarm/config.json.
    zmodload -F zsh/stat b:zstat 2>/dev/null
    if [[ "$OSTYPE" == darwin* ]]; then
      __gitrepo_conf="${CRABSWARM_CONF:-$HOME/Library/Application Support/crabswarm/config.json}"
    else
      __gitrepo_conf="${CRABSWARM_CONF:-${XDG_CONFIG_HOME:-$HOME/.config}/crabswarm/config.json}"
    fi
    __gitrepo_mtime=()
    zstat -A __gitrepo_mtime +mtime -- "$__gitrepo_conf" 2>/dev/null
    __gitrepo_key="${commands[crabswarm]:A}|${__gitrepo_conf:A}|${__gitrepo_mtime[1]:-}|${CRABSWARM_GIT_REPO_BASE_DIR:-}|${HOME}"
    __gitrepo_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/gitrepo-root"
    __gitrepo_cached_key=""
    if [[ -r "$__gitrepo_cache" ]]; then
      { read -r __gitrepo_cached_key; read -r GITREPO_ROOT; } < "$__gitrepo_cache"
    fi
    if [[ "$__gitrepo_cached_key" != "$__gitrepo_key" || -z "$GITREPO_ROOT" ]]; then
      GITREPO_ROOT=$(crabswarm config --format '{{.GitRepoBaseDir}}' 2>/dev/null)
      if [[ -n "$GITREPO_ROOT" ]]; then
        mkdir -p "${__gitrepo_cache:h}" 2>/dev/null
        printf '%s\n%s\n' "$__gitrepo_key" "$GITREPO_ROOT" > "$__gitrepo_cache" 2>/dev/null
      fi
    fi
    unset __gitrepo_conf __gitrepo_mtime __gitrepo_key __gitrepo_cache __gitrepo_cached_key
  else
    GITREPO_ROOT=$(crabswarm config --format '{{.GitRepoBaseDir}}' 2>/dev/null)
  fi
  export GITREPO_ROOT="${GITREPO_ROOT:-$HOME/gitrepo}"
fi
