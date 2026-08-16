#!/usr/bin/env bash

set -euo pipefail

if ! command -v git >/dev/null; then
  echo "apm-bump: git not found" >&2
  exit 1
fi

rm -rf ./.agents ./.claude ./.codex

if [ ! -e ./.bare ]; then
  apm install --update -t codex,claude
  apm compile -t codex
  exit 0
fi

# worktree base dir: sources resolve from the default-branch worktree,
# outputs are written back here via --root.
branch=$(git --git-dir=.bare symbolic-ref --short HEAD 2>/dev/null || true)
if [ -n "${branch}" ] && [ -d "./${branch}" ]; then
  wt=./${branch}
elif [ -d ./main ]; then
  wt=./main
elif [ -d ./master ]; then
  wt=./master
else
  echo "apm-bump: no worktree dir found (tried '${branch:-<none>}', main, master)" >&2
  exit 1
fi
pushd "${wt}" >/dev/null
apm install --update -t codex,claude --root ..
apm compile -t codex --root ..
popd >/dev/null
