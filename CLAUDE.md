# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a dotfiles repository that manages development environments and tools installation across Linux/macOS systems. The codebase includes:

- **Deno-based TypeScript scripts** for configuration management (`src/`)
- **Go-based package managers** (`ngpkgmgr/`, `nggitmgr/`) for SDK and tool installation
- **Configuration files** for nvim, tmux, lazygit, wezterm (`.config/`)
- **Shell scripts** for SDK installation and system setup

## Key Commands

### Installation & Setup
```bash
# Install prerequisites (run once)
sudo apt update && sudo apt install -y make build-essential gcc clang xsel p7zip-full jq tmux

# Install SDKs (Go, Node.js, Python, Rust, etc.)
./install_sdk.sh

# Install dotfiles (symlinks configs to ~/.config/)
~/.deno/bin/deno task install

# Source updated bashrc
. ~/.bashrc
```

### Development Tasks
```bash
# Update all SDKs and tools
deno task update:all

# Update individual components
deno task sdk:update
deno task basetool:update  
deno task gotools:update

# Daily update (pulls git changes, syncs wezterm config to host, rate-limited to 16hr intervals)
deno task update:daily

# Manually sync wezterm config to Windows host (WSL only)
deno task wezterm:sync

# Install/manage JDK versions
deno task jdk:install
deno task jdk:dotenv >> ~/.config/env/jdk.env
```

### Go Projects (ngpkgmgr, nggitmgr)
```bash
# Build Go binaries
cd ngpkgmgr && go build
cd nggitmgr && go build

# Run package manager
~/bin/ngpkgmgr --dir ./ngpkgmgr/preset/sdk install
```

## Architecture

### Configuration Management
- **Environment Loading**: `~/.config/env/*.env` files loaded automatically, followed by `*.sh` files
- **Symlink Strategy**: Dotfiles are symlinked from `.config/` to `~/.config/` via `src/install.ts`
- **PATH Management**: Tools installed to `~/bin/` and `~/.local/*/bin/`, managed via `~/.config/env/00_path.sh`

### Package Management System
- **ngpkgmgr**: Meta package manager that executes shell scripts for install/update operations
  - Presets in `ngpkgmgr/preset/` define installation procedures for SDKs and tools
  - Cross-platform support (Linux, Darwin, Windows) with architecture detection
- **nggitmgr**: Simple git repository manager for cloning and organizing repos

### SDK Installation Flow
1. `install_sdk.sh` detects OS/architecture and copies prebuilt binaries to `~/bin/`
2. `ngpkgmgr` reads JSON preset files and executes corresponding shell scripts
3. SDKs installed to `~/.local/` with version management
4. Environment variables configured in `~/.config/env/`

### Neovim Configuration
- Based on NvChad with custom modifications
- Structure: `configs/` (eager), `plugins/` (lazy.nvim), `setup/` (auto-loaded)
- Plugin configs auto-injected from directory structure
- Requires BlexMono Nerd Font

## File Locations

- **Deno tasks**: `deno.json` - main task definitions
- **Go modules**: `ngpkgmgr/go.mod`, `nggitmgr/go.mod`
- **SDK presets**: `ngpkgmgr/preset/sdk/` - installation scripts for development tools
- **Tool presets**: `ngpkgmgr/preset/basetool/`, `ngpkgmgr/preset/gopkg/`
- **Config templates**: `.config/nvim/`, `.config/tmux/`, `.config/lazygit/`, `.config/wezterm/`

## Serena Memory System

The project uses a `.serena` memory system to store important context and information. Available memories include:

- **project_overview**: High-level description of the repository purpose and components
- **architecture_details**: Detailed technical architecture and implementation patterns
- **code_style_conventions**: Project-specific coding standards and patterns
- **suggested_commands**: Commonly used commands for development and maintenance
- **task_completion_checklist**: Standard checks to perform when completing tasks

These memories can be accessed to provide consistent context across sessions and ensure adherence to project patterns.