#!/usr/bin/env bash

set -eCu

if [ ! -d ./.claude ]; then
  echo "./.claude not found"
  exit 1
fi

mkdir ./.claude/agents/ -p
cp -r $HOME/.dotfiles/agents/agents/* ./.claude/agents/
mkdir -p ./.claude/skills/
cp -r $HOME/.dotfiles/agents/skills/* ./.claude/skills/
