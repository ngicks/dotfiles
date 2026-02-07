#!/usr/bin/env bash

set -eCu

touch AGENTS.md

if [ $(stat -c %s ./AGENTS.md) -eq "0" ]; then
  cp $HOME/.dotfiles/agents/AGENTS.md ./AGENTS.md
fi

ln -fs AGENTS.md CLAUDE.md
ln -fs AGENTS.md GEMINI.md
