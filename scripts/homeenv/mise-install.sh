#!/usr/bin/env bash

set -e

go_tools=(
  "go:github.com/nametake/golangci-lint-langserver"
  "go:github.com/golangci/golangci-lint/cmd/golangci-lint"
  "go:github.com/golangci/golangci-lint/v2/cmd/golangci-lint"
  "go:github.com/chrishrb/go-grip"
  "go:github.com/mattn/memo"
)

pushd ./config/mise/
  # it always fails because of read-only lock file
  mise install
  mise install -f "${go_tools[@]}"
  mise prune -y
popd
