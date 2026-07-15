# dotfiles

My dotfiles.

Stores config files for tools and setup scripts for them.

Combination of `nix`(for most of packages) and `mise`(anything that can not be managed via nix / rapidly developed tools)

## Intended Environment

Only intended for `linux/macos` and `x86_64/aarch64` and the env must have `bash`.  
The RockyLinux or other SELinux enabled environments are out of support because `nix` does not work on the environments.

## isntall prerequisites

### Nerd fonts

You must download nerd-fonts if your terminal emulator doesn't support it natively.

```
cd /path/to/you/want/to/store/nerdfont/repo
git clone https://github.com/ryanoasis/nerd-fonts .

# read the script carefully before executing it.

# On windows
.\install.ps1
# On unix-like
./install.sh
```

If you are running a terminal on windows and running linux on wsl2 instances, then install fonts to windows(`install.ps1`).

### All others

All other prerequisites are installed via `./homeenv-install.sh` via `./scripts/homeenv/system-prerequisites.sh`

## Install Dotfiles

### Install

```
./homeenv-install.sh
```

### Disable daily auto-update if needed

```
touch "${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/.no_update_daily"
```

## Set up environment

### The environment specific configs under ${XDG_CONFIG_HOME:-$HOME/.config}/env

All `*.sh` and `*.env` files under `${XDG_CONFIG_HOME:-$HOME/.config}/env` are loaded.

### Very first rc file

The file placed at `"$HOME/.config/env/.first_rc"` is sourced right after home-manager resources.  
You may define `SYSTEM_PKG_UPDATE_NOT_ALLOWED=1` there to skip system package manager updates.

## Each configs / target tools

- cmdman
  - my own daemonizor tool: https://github.com/ngicks/cmdman
- containers-quadlet
  - Quadlet files. Load location is altered by podman installed via `podman-static-dist`(my tool) and / or `./config/environment.d/environment.d/75-podman.conf`
- crabswarm
  - my own swis army knife utilities: https://github.com/ngicks/crabswarm
- dotfilesmgr
  - config for the daemon managing dotfiles repo: https://github.com/ngicks/dotfiles-tool/tree/main/dotfilesmgr
- environment.d
  - config files for systemd user units
- lazygit
  - TUI for git: https://github.com/jesseduffield/lazygit
- loginscript
  - scripts sourced by shells
- mise
  - tool / task managements
- nix
- nvim
  - neovim, a TUI editor: https://neovim.io/
- systemd
  - systemd user units
- tmux
  - terminal multiplexer / session persister
- wezterm
  - terminal emulator
  - config is not directly loaded if env is wsl and wezterm is installed on Windows size. In that case config files are copied thourgh WSL `/mnt/c/...`
- zellij
  - terminal multiplexer / session persister, more focused on workspace management.
