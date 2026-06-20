#!/usr/bin/env bash

set -eCu

printf "%s\n" "--mount type=volume,src=local-bin,dst=/root/.local/bin"
printf "%s\n" "--mount type=volume,src=claude-bin,dst=/root/.local/share/claude"
printf "%s\n" "--mount type=volume,src=claude-config,dst=/root/.config/claude"
printf "%s\n" "--mount type=volume,src=gemini-config,dst=/root/.gemini"
printf "%s\n" "--mount type=volume,src=codex-config,dst=/root/.codex"
printf "%s\n" "--mount type=volume,src=gh-config,dst=/root/.config/gh"
printf "%s\n" "--mount type=volume,src=glab-config,dst=/root/.config/glab-cli"
