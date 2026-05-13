#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "usage: ./run-in-new-interactive-shell.sh cwd command(one-liner)..."
  exit 1
fi

_cid=$(cmdman run --rm -t -C "$1" -- zsh)
# let hook refresh
cmdman send-keys "$_cid" "C-c"
cmdman send-keys "$_cid" "C-c"
cmdman send-keys "$_cid" "${*:2} && exit 0 || exit \$?"
cmdman send-keys "$_cid" "Enter"
if [[ -t 0 ]]; then
  cmdman attach "$_cid"
else
  cmdman wait "$_cid"
fi

