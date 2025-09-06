#!/bin/bash

set -e

echo "Checking and installing common tools..."

# Check and install Oh My Zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "  Oh My Zsh already installed, skipping"
else
    echo "  Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo "Common tools check completed."
