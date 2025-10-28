# AGENTS.md

This file provides guidance to LLM cli agents when working with code in this repository.

## Repository Overview

This is a dotfiles repository that manages development environments and tools installation across Linux/macOS systems. The codebase includes:

- **Mise** - Primary tool version manager for SDKs and development tools
- **Deno-based TypeScript scripts** for configuration management (`src/`)
- **Configuration files** for nvim, tmux, lazygit, wezterm (`.config/`)
- **Shell scripts** for dependency management (`dep/`)
- **Docker-based development environment** (`devenv.Dockerfile`)

## Key Commands

### Installation & Setup

```bash
# Install prerequisites and mise (Ubuntu/Debian or macOS)
./install_dependencies.sh

# Install dotfiles (symlinks configs to ~/.config/)
~/.local/bin/mise exec -- deno task install

# Source updated bashrc/zshrc
. ~/.bashrc  # or . ~/.zshrc
```

### Mise Tool Management

```bash
# List installed tools
mise ls

# Install all tools from config
mise install

# Update all tools
mise up

# Check mise status
mise doctor
```

### Development Tasks

```bash
# Daily update (pulls git changes, syncs wezterm config to host, rate-limited to 16hr intervals)
deno task update:daily

# Install/manage JDK versions (optional)
deno task jdk:install
deno task jdk:dotenv >> ~/.config/env/jdk.env
```

### Docker Development Environment

```bash
# Build development environment container
deno task devenv:build

# Build with version bump
deno task devenv:build:bump
```

## Architecture

### Tool Management with Mise

**Mise** is the central tool version manager that replaces the old ngpkgmgr/nggitmgr system.

**Configuration Files**:

- `.config/mise/config.toml` - Main mise configuration with all tool definitions
- `.config/initial_path/01_mise.sh` - Shell activation script (auto-loaded at shell startup)

**Managed Tools** (via different backends):

- **Core runtimes**: deno, node, bun, python, uv, ruby, rust, go
- **Go tools** (`go:` backend): gopls, lazygit, fzf, goimports, gofumpt, golangci-lint, delve, buf, protoc-gen-\*
- **Cargo tools** (`cargo:` backend): yazi, ripgrep, zellij, bat, exa, fd-find, bottom, du-dust, procs
- **NPM tools** (`npm:` backend): claude-code, gemini-cli, MCP servers
- **Pipx tools** (`pipx:` backend): serena, spec-kit
- **GitHub releases**: neovim

**Mise Features**:

- `auto_install = true` - Automatically installs missing tools
- `lockfile = true` - Creates config.lock for reproducible installs
- `binstall = true` - Uses cargo-binstall for faster Rust tool installation
- `uvx = true` - Uses uvx for pipx backend
- `bun = true` - Uses bun for npm backend

### Configuration Management Flow

1. **Environment Loading**:
   - `~/.config/env/*.env` files loaded first (key=value pairs)
   - `~/.config/env/*.sh` files loaded second (bash scripts)
   - Mise activation happens in `01_mise.sh` (auto-loaded)
   - Allows layered configuration with overrides

2. **Symlink Strategy**:
   - Source: Repository's `.config/` directory
   - Destination: User's `~/.config/` directory
   - Managed by: `src/install.ts` Deno script
   - Non-destructive: Backs up existing configs

3. **PATH Management**:
   - Mise shims: `~/.local/share/mise/shims/` (managed by mise)
   - User binaries: `~/bin/`
   - SDK binaries: `~/.local/*/bin/`
   - PATH setup: Managed via `~/.config/env/00_path.sh`

### Installation Flow

1. `install_dependencies.sh` detects OS and package manager (apt/brew)
2. Installs system packages via `dep/apt/` or `dep/brew/`
3. Installs mise via `dep/common/mise.sh` (runs `curl https://mise.run | sh`)
4. Installs common tools via `dep/common/` (Oh My Zsh, dasel)
5. `mise_install.sh` activates mise and runs `mise install` to install all tools
6. `deno task install` symlinks configuration files to `~/.config/`
7. Shell restart loads mise activation and all tools become available

### Dependency Installer Structure

The `install_dependencies.sh` script supports multiple package managers:

- `dep/apt/` - Ubuntu/Debian system packages
- `dep/brew/` - macOS Homebrew packages
- `dep/common/` - Cross-platform tools (mise, Oh My Zsh, dasel)

Scripts executed as separate processes (not sourced) for environment isolation.

### Neovim Configuration

- **Base**: NvChad framework
- **Structure**:
  - `configs/` - Eagerly loaded configuration files
  - `plugins/` - Lazy.nvim plugin definitions (auto-injected)
  - `setup/` - Auto-loaded setup scripts
  - `toggleterm_cmd/` - Manually loaded terminal commands
- **Font Requirement**: BlexMono Nerd Font

### Tmux Configuration

- Uses `xterm-256color` for better compatibility with older software
- Status line features:
  - Colored mode indicator: bright green (VIEW), blue (COPY)
  - Colored prefix indicator: bright violet (ON), dark purple (OFF)
- Vim-like copy mode
- Neovim-like pane navigation: prefix+{h,j,k,l}
- Neovim-like pane splitting: prefix+s (horizontal), prefix+v (vertical)

## File Locations

- **Deno tasks**: `deno.json` - Main task definitions
- **TypeScript source**: `src/` - Installation and management scripts
  - `src/install.ts` - Dotfiles symlink manager
  - `src/update_daily.ts` - Daily update automation
  - `src/devenv_build.ts` - Docker environment builder
  - `src/jdk.ts` - JDK version manager
- **Mise configuration**: `.config/mise/config.toml` - Tool definitions and settings
- **Dependency scripts**: `dep/` - Package manager specific installers
  - `dep/apt/` - Ubuntu/Debian packages
  - `dep/brew/` - macOS packages
  - `dep/common/` - Cross-platform tools (mise, Oh My Zsh, dasel)
- **Config templates**: `.config/nvim/`, `.config/tmux/`, `.config/lazygit/`, `.config/wezterm/`
- **Environment configs**: `.config/env/` - Shell environment setup (auto-loaded)

## Platform Support

- **Primary target**: Linux/amd64 with `/bin/bash` or `/bin/zsh`
- **Partial support**: macOS (darwin)
- **WSL-specific features**: Wezterm config sync to Windows host via `update:daily` task
