#!/usr/bin/env bash

runner=$(dirname $0)/../../devenv/scripts/run-devenv.sh
# Let mise up be called in container
# because it always tries to update things
# under `~/.config/mise/`.
go_tools=(
  "go:github.com/nametake/golangci-lint-langserver"
  "go:github.com/golangci/golangci-lint/cmd/golangci-lint"
  "go:github.com/golangci/golangci-lint/v2/cmd/golangci-lint"
  "go:github.com/chrishrb/go-grip"
  "go:github.com/mattn/memo"
)

$runner \
  "--mount type=bind,src=$HOME/.dotfiles/config/mise/,dst=/mise \
  --env MISE_GLOBAL_CONFIG_FILE=/mise/mise.toml \
  --workdir /mise" \
  "-lc" "mise up && mise install -f ${go_tools[*]} && mise prune -y"

# Not sure, often it leaves old lock entries.

$runner \
  "--mount type=bind,src=$HOME/.dotfiles/config/mise/,dst=/mise \
  --env MISE_GLOBAL_CONFIG_FILE=/mise/mise.toml \
  --workdir /mise" \
  "-lc" "mise lock --global"
