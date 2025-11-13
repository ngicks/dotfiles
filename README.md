# dotfiles

My dotfiles.

Devenv setup scripts + configuration for tools.

Just like others do, install scripts symlinks contents under `./.config/` to under `${XDG_CONFIG_HOME:-$HOME/.config}/`

## Intended Environment

Only intended for `linux/amd64` and the env must have `/bin/bash`.

Some scripts may leave switch pattern for other than `linux/amd64`, e.g. `windows`/`darwin`, architectures like `arm64`. But they are totally WIP stubs.

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

### Deps

Only `apt` or `brew` is supported.

```
./install_dependencies.sh
```

Modify `~/.zshrc`.

```shell
export ZSH_THEME="obraun"
```

## Install Dotfiles

### Linking

```
~/.local/bin/mise exec deno -- deno task install
```

Restart shell after installation

### Disable daily auto-update if needed

```
touch "${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/.no_update_daily"
```

## Install SDK

`mise install`

## Set up configs under ${XDG_CONFIG_HOME:-$HOME/.config}/env

All `*.sh` and `*.env` files under `${XDG_CONFIG_HOME:-$HOME/.config}/env` are loaded.

## Build optional tools

Things under `build`

### podman-static

[podman-static](https://github.com/mgoltzsche/podman-static.git)

## About each config

Things under `.config`

### dotfiles_init

Automatically loaded in `~/.zshrc`.

Default-ish environment variables are defined in there.

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
