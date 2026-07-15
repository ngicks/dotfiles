# dotfiles

My dotfiles.

Stores config files for tools and setup scripts for them.

Combination of `nix`(for most of packages) and `mise`(anything that can be managed via nix)

## Intended Environment

Only intended for `linux/macos` and `x86_64/aarch64` and the env must have `bash`.

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

### zsh (BEFORE nix)

Install zsh with the system package manager **before** installing nix:

```
sudo apt install -y zsh
```

The nix installer appends its profile hook only to global zsh rc files that
exist at install time. On Debian/Ubuntu zsh reads `/etc/zsh/zshrc` (not
`/etc/zshrc`, which the installer creates as a fallback), so installing zsh
after nix leaves zsh login shells without nix on PATH.

If you got the order wrong, `./homeenv-install.sh` (via
`scripts/homeenv/system-prerequisites.sh`) re-adds the missing hook.

### nix

https://nixos.org/download/#nix-install-windows

```
# share `/nix` dir
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
# or single user installation
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon
```

## Install Dotfiles

### Install

```
./homeenv-install.sh
```

### mise moon backend plugin

My own tools are managed through `mise` with the `moon:` backend prefix in
`config/mise/mise.toml`, hosted in
[dotfiles-tool](https://github.com/ngicks/dotfiles-tool) (vendored as the
`./tool` submodule). `./dotfiles-daemon` and `./builder/podman-static-dist`
will be moved there. Installing them requires
[mise-moon-backend-plugin](https://github.com/ngicks/mise-moon-backend-plugin):

```
mise plugin install moon https://github.com/ngicks/mise-moon-backend-plugin
```

Install it once mise is on PATH (i.e. after `./homeenv-install.sh`), then re-run
`mise install` to pick up the `moon:` tools.

### Disable daily auto-update if needed

```
touch "${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/.no_update_daily"
```

## Set up configs under ${XDG_CONFIG_HOME:-$HOME/.config}/env

All `*.sh` and `*.env` files under `${XDG_CONFIG_HOME:-$HOME/.config}/env` are loaded.

## Build optional tools

Things under `build` and `builder`

### podman-static

[podman-static](https://github.com/mgoltzsche/podman-static.git)

`builder/podman-static-dist` will be moved to
[dotfiles-tool](https://github.com/ngicks/dotfiles-tool) (the `./tool`
submodule) and installed through mise.

`podman-static-dist build` writes the dist archive to its standard location
(`${XDG_CACHE_HOME:-~/.cache}/dotfiles/build/podman-static/out/podman-static-<tag>.tar.zst`);
`podman-static-dist install` extracts it to
`${XDG_DATA_HOME:-~/.local/share}/podman-dist/<tag>` and wires it into the
host home. Nothing is baked into the devenv image.

At `devenv_run.sh` time the host dist is mounted read-only into the container
(binaries and configs; `DEVENV_PODMAN_DIST=<dir|0>` overrides the dist dir or
skips it), and the container-specific config variants from the dist's
`etc/containers/__additional_podman-in-podman/` (concrete `/root` paths) are
bind-mounted over their default-named counterparts in `~/.config/containers`,
so the container never reads the host-interpolated configs. The host image
store is mounted as an additional read-only image store by default
(`DEVENV_PODMAN_IMAGE_STORE=0` to skip). Running podman inside is enabled by
default (`--device /dev/fuse`, `--security-opt label=disable`);
`DEVENV_PODMAN=0` opts out.

## About each config

Things under `.config`

### lazygit

- Nothing specific is defined. Just changed copy command to `xsel -bi`.

### mise

- All SDKs / tools.

### nvim

#### It's based on NvChad

Say thanks to https://nvchad.com/

#### Changes / Structures

- `configs`: eagerly loaded config files are located here.
- `plugins`: `init.lua` lists all `lazy.nvim` plugins.
  - configs files for plugins are splitted to dirs and automatically created.
    - you can define `init`, `opts`, `config`, `main`, `build` in the created lua scripts.
    - those functions are injected automatically.
- `setup`: eagerly loaded setup files; automatically loaded.
- `toggleterm_cmd`: manually loaded by mapping.

### tmux

- `set -g default-terminal 'xterm-256color'`:
  - The old tmux set $TERM `screen`. as of Ubuntu 24.04, the current version of
    tmux place it to tmux-256color.
  - Some old software deems it as a lack of capability and launch in broken
    state.
  - `xterm-256color` is causing no trouble at this moment.
- status line:
  - colored mode indicator: bright green for VIEW mode, blue for COPY mode
  - colored prefix indicator: bright violet when ON(prefix is pressed), dark purple when OFF(prefix is not active).
- vim like copy mode.
- nvim like pane move: prefix+{h,j,k,l} to move around
- nvim like pane split: prefix+s to split horizontally, prefix+v to virtically

### wezterm

- Terminal emulator.

### zellij

- Keymaps / layouts.
