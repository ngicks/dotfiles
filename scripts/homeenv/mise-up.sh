#!/usr/bin/env bash

set -uo pipefail

repo_root=$(cd $(dirname $0)/../../ && pwd -P)

run_in_container=$repo_root/devenv/scripts/run-devenv.sh

mise_install_f=$(cd $(dirname $0) && pwd -P)/mise-install-f-if-missing.sh

# Installs often fail midway; commit each step's config/mise changes right away
# so a later failure does not leave the bumps uncommitted. The pathspec keeps
# whatever else is staged out of these commits.
commit_mise_config() {
  local message=$1
  if [[ -z "$(git -C "$repo_root" status --porcelain -- config/mise)" ]]; then
    return 0
  fi
  git -C "$repo_root" add -A -- config/mise &&
    git -C "$repo_root" commit -m "$message" -- config/mise
}

echo ""
echo "mise up"
echo ""

$run_in_container \
  "--mount type=bind,src=$HOME/.dotfiles/config/mise/,dst=/mise \
  --env MISE_GLOBAL_CONFIG_FILE=/mise/mise.toml \
  --workdir /mise" \
  "-lc" "mise up"

commit_mise_config "👷: mise up"

echo ""
echo "mise install -f if missing"
echo ""

$run_in_container \
  "--mount type=bind,src=$HOME/.dotfiles/config/mise/,dst=/mise \
  --mount type=bind,src=$mise_install_f,dst=/mise-install-f-if-missing.sh,ro \
  --env MISE_GLOBAL_CONFIG_FILE=/mise/mise.toml \
  --workdir /mise" \
  "-lc" "/mise-install-f-if-missing.sh"

commit_mise_config "👷: mise install"

echo ""
echo "mise prune"
echo ""

$run_in_container \
  "--mount type=bind,src=$HOME/.dotfiles/config/mise/,dst=/mise \
  --env MISE_GLOBAL_CONFIG_FILE=/mise/mise.toml \
  --workdir /mise" \
  "-lc" "mise prune -y"

commit_mise_config "👷: mise prune"

echo ""
echo "mise lock"
echo ""

# -g: MISE_GLOBAL_CONFIG_FILE makes /mise/mise.toml the global config, and
# without -g mise scopes to the project config root and finds no tools to
# lock. No tool args: mise lock resolves every requested version from the
# config itself; listing installed versions via mise ls picked the stale
# inactive install when two versions of a tool were present.
$run_in_container \
  "--mount type=bind,src=$HOME/.dotfiles/config/mise/,dst=/mise \
  --env MISE_GLOBAL_CONFIG_FILE=/mise/mise.toml \
  --workdir /mise" \
  "-lc" "mise lock -g"

commit_mise_config "👷: mise lock"
