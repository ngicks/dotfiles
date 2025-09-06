#!/bin/bash

set -e

echo "Installing packages via apt..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEP_DIR="$(dirname "$SCRIPT_DIR")"

# Collect all apt packages from list files
PACKAGES=()
for list_file in "$DEP_DIR"/lists/*.txt; do
    if [ -f "$list_file" ]; then
        # Extract apt packages from the list file
        while IFS= read -r line; do
            # Skip comments and empty lines
            [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
            # Check if line starts with "apt:"
            if [[ "$line" =~ ^apt:(.*)$ ]]; then
                # Extract package list (may be comma-separated)
                pkg_list="${BASH_REMATCH[1]}"
                # Split by comma and trim whitespace
                IFS=',' read -ra pkg_array <<< "$pkg_list"
                for pkg in "${pkg_array[@]}"; do
                    # Trim leading/trailing whitespace
                    pkg=$(echo "$pkg" | xargs)
                    [ -n "$pkg" ] && PACKAGES+=("$pkg")
                done
            fi
        done < "$list_file"
    fi
done

# Remove duplicates while preserving order
PACKAGES=($(printf "%s\n" "${PACKAGES[@]}" | awk '!seen[$0]++'))

if [ ${#PACKAGES[@]} -gt 0 ]; then
    echo "Installing the following packages: ${PACKAGES[*]}"
    sudo apt update
    sudo apt install -y "${PACKAGES[@]}"
    echo "apt packages installation completed."
else
    echo "No apt packages to install."
fi
