#!/usr/bin/env bash

set -eCu

printf "%s\n" "--mount type=volume,src=local-bin,dst=/root/.local/bin"
printf "%s\n" "--mount type=volume,src=claude-bin,dst=/root/.local/share/claude"
printf "%s\n" "--mount type=volume,src=claude-config,dst=/root/.config/claude"
printf "%s\n" "--mount type=volume,src=gemini-config,dst=/root/.gemini"
printf "%s\n" "--mount type=volume,src=codex-config,dst=/root/.codex"
# codex hardcodes <CODEX_HOME>/logs_2.sqlite and its WAL churn burns the
# SSD-backed volume; ensure-podman-volume.sh symlinks it under logs-ram.
printf "%s\n" "--mount type=tmpfs,dst=/root/.codex/logs-ram,tmpfs-size=512m"
printf "%s\n" "--mount type=volume,src=apm-config,dst=/root/.apm"
printf "%s\n" "--mount type=volume,src=hf-token,dst=/root/.config/huggingface"
printf "%s\n" "--mount type=volume,src=gh-config,dst=/root/.config/gh"
printf "%s\n" "--mount type=volume,src=glab-config,dst=/root/.config/glab-cli"
