#!/bin/bash

# Check and install dasel
if command -v dasel &> /dev/null || [ -f "$HOME/.local/bin/dasel" ]; then
    echo "  dasel already installed, skipping"
else
    echo "  Installing dasel..."
    mkdir -p ~/.local/bin
    pushd ~/.local/bin > /dev/null

    # Detect OS and download appropriate binary
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "    Downloading dasel for macOS..."
        curl -L https://github.com/TomWright/dasel/releases/download/v2.8.1/dasel_darwin_amd64.gz -o dasel.gz
    else
        echo "    Downloading dasel for Linux..."
        curl -L https://github.com/TomWright/dasel/releases/download/v2.8.1/dasel_linux_amd64.gz -o dasel.gz
    fi

    gzip -d ./dasel.gz
    chmod +x dasel
    popd > /dev/null
    echo "  dasel installation completed"
fi
