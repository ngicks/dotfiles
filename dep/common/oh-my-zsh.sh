#!/bin/bash

set -e

# Check and install Oh My Zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "  Oh My Zsh already installed, skipping"
else
    echo "  Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

