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

### Install zsh and make it the login shell

The shell config is written for zsh. `./homeenv-install.sh` installs zsh through the system package manager, but it does not change the login shell.
Do that once by hand, and point it at the system zsh, not the one under `~/.nix-profile`.
The nix path is not listed in `/etc/shells`, and a login shell that lives inside a nix profile breaks whenever the profile is rebuilt or nix is unavailable.
The system zsh reads the same `~/.zshenv` / `~/.zprofile` / `~/.zshrc` that home-manager writes, so nothing is lost.

Install zsh if it is missing:

```
# Debian / Ubuntu
sudo apt install zsh
# Fedora / RHEL family
sudo dnf install zsh
# Arch
sudo pacman -S zsh
# macOS ships zsh as the default shell already
```

Change the login shell to the system zsh:

```
zsh_path="$(command -v zsh)"          # expect /usr/bin/zsh or /bin/zsh
grep -qx "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells
chsh -s "$zsh_path"
```

Log out and back in for the change to apply. On WSL, close the terminal and open a new one; `wsl --shutdown` from Windows is not required.

Confirm with:

```
echo "$SHELL"   # the system zsh path
zsh --version
```

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
