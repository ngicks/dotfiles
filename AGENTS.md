# AGENTS.md

This file provides guidance to LLM cli agents when working with code in this repository.

## Important

- Use serena where possible.
- Use context7 for tool specific knowledge.
- If you are not `codex`:
  - ALWAYS output plans to under `./doc/plans`, following file format `${RFC3339-DATETIME-FORMAT}-${name-on-plan}.md`
  - ALWAYS ask `codex` to review your plan, using `codex review`.
- Before planning, you may lookup through `./doc/plans` to retrieve important context.
- In difficult reserach, complex planning, ask `codex` for help using `codex mcp` tool.
- You might be in a restricted enviroment: some commands may fail and some special files may not be present (e.g. `/dev/kvm`).
- Remenber to use the agent-memory skill the moment user's preference become prominent.

## Repository Overview

This is a dotfiles repository that manages development environments and tools installation across Linux/macOS systems. The codebase includes:

- **Nix Home Manager** - Primary configuration manager for packages and dotfiles symlinks
- **Mise** - Secondary tool manager for language-specific development tools
- **Deno-based TypeScript scripts** for automation (`src/`)
- **Configuration files** for nvim, tmux, lazygit, wezterm, zellij (`config/`)
- **Nix flake** for reproducible home configuration (`nix-craft/`)
- **Docker-based development environment** (`devenv.Dockerfile`)

## Key Commands

### Installation & Setup

```bash
# Install/sync all configurations (runs home-manager switch)
./homeenv-install.sh

# Upgrade all packages
./homeenv-upgrade.sh

# Source updated shell config
. ~/.zshrc
```

### Nix Home Manager

```bash
# Switch to updated configuration
cd nix-craft && nix run .#home-manager -- switch -b backup --flake .#default --impure

# Update flake inputs
cd nix-craft && nix flake update

# Garbage collection
nix-collect-garbage --delete-older-than 7d
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

### Docker Development Environment

```bash
# Build development environment container
deno task devenv:build
```

## Architecture

### Configuration Management with Nix Home Manager

**Nix Home Manager** is the central configuration manager, defined in `nix-craft/flake.nix`.

**Key Files**:

- `nix-craft/flake.nix` - Flake definition with inputs (nixpkgs, home-manager)
- `nix-craft/home/home.nix` - Main home configuration with packages and imports
- `nix-craft/home/*/default.nix` - Per-program module configurations

**Managed via Home Manager**:

- **Core runtimes**: nodejs, deno, bun, python, uv, ruby, rustup, go
- **CLI utilities**: ripgrep, bat, eza, fd, htop, bottom, dust, procs, sd, yazi, zoxide
- **Kubernetes/DevOps**: kubectl, helm, kompose, kops, sops, age, nerdctl
- **Git tools**: gh, glab
- **Protobuf**: protobuf, buf, protoc-gen-go, protoc-gen-go-grpc, grpc-gateway
- **System tools**: gnupg, gnumake, gcc, jq, curl, wget, and more

**Symlink Strategy** (via `xdg.configFile`):

- Source: Repository's `config/` directory
- Destination: User's `~/.config/` directory
- Managed by: Home Manager `xdg.configFile` declarations
- Automatic backup: Uses `-b backup` flag during switch

### Secondary Tool Management with Mise

**Mise** handles tools that benefit from version management or aren't well-suited for Nix.

**Configuration**: `config/mise/mise.toml`

**Managed Tools** (via different backends):

- **LLM tools** (`npm:` backend): gemini-cli, codex
- **MCP servers** (`npm:`, `pipx:` backends): context7-mcp, serena
- **Go development** (`go:` backend): gopls, goimports, gofumpt, staticcheck, golangci-lint, delve, gotests
- **Helm tools** (`aqua:` backend): chart-releaser, chart-testing
- **Other**: ruff, zenn-cli, betterproto2_compiler

**Mise Settings**:

- `auto_install = true` - Automatically installs missing tools
- `lockfile = true` - Creates mise.lock for reproducible installs
- `binstall = true` - Uses cargo-binstall for faster Rust tool installation
- `uvx = true` - Uses uvx for pipx backend

### Shell Configuration Flow

1. **Home Manager** generates `.zshrc` with embedded configuration
2. **loginscript loading**: Sources `~/.config/loginscript/*.sh` (from `config/loginscript/`)
3. **Environment loading**: Sources `~/.config/env/*.env` then `~/.config/env/*.sh`
4. **Daily update check**: Runs `deno task update:daily` if update is due

### Installation Flow

1. **Prerequisites**: Nix package manager with flakes enabled
2. `homeenv-install.sh` runs:
   - System package manager update
   - Neovim lazy.nvim plugin restore
   - Mise tool installation
   - Home Manager switch (symlinks configs)
3. Shell restart loads all configurations

### Upgrade Flow

`homeenv-upgrade.sh` runs:

- System package manager update
- Mise tool upgrades
- Neovim lazy.nvim sync
- Nix flake update

### Neovim Configuration

- **Base**: NvChad framework
- **Location**: `config/nvim/`
- **Structure**:
  - `lua/config/` - Configuration files
  - `lua/plugins/` - Lazy.nvim plugin definitions
  - `lua/setup/` - Setup scripts
  - `lua/toggleterm_cmd/` - Terminal command definitions
  - `lua/func/` - Custom functions

### Tmux Configuration

- **Location**: `config/tmux/`
- Uses `xterm-256color` for better compatibility
- Status line features:
  - Colored mode indicator: bright green (VIEW), blue (COPY)
  - Colored prefix indicator: bright violet (ON), dark purple (OFF)
- Vim-like copy mode
- Neovim-like pane navigation: prefix+{h,j,k,l}
- Neovim-like pane splitting: prefix+s (horizontal), prefix+v (vertical)

## File Locations

- **Nix flake**: `nix-craft/flake.nix` - Main flake definition
- **Home config**: `nix-craft/home/home.nix` - Package list and module imports
- **Program modules**: `nix-craft/home/*/default.nix` - Per-program configurations
- **Deno tasks**: `deno.json` - Task definitions
- **TypeScript source**: `src/` - Automation scripts
  - `src/update_daily.ts` - Daily update automation
  - `src/devenv_build.ts` - Docker environment builder
- **Mise configuration**: `config/mise/mise.toml` - Development tool definitions
- **Config templates**: `config/nvim/`, `config/tmux/`, `config/wezterm/`, `config/zellij/`
- **Login scripts**: `config/loginscript/` - Shell startup scripts
- **Homeenv scripts**: `scripts/homeenv/` - Modular installation scripts
- **Custom packages**: `nix-craft/pkgs/` - Nix package definitions

## Platform Support

- **Primary target**: Linux/amd64 with Nix and `/bin/zsh`
- **Supported systems**: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin
- **WSL-specific features**: Wezterm config sync to Windows host via `update:daily` task
