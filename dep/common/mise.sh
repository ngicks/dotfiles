#!/bin/bash

set -e

if [ ! -x $HOME/.local/bin/mise ]; then
  curl https://mise.run | sh
else 
  echo "  mise already installed"
fi
