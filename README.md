# dotfiles

## install SDK

First, install SDKs by `./install_sdk.sh`

All other scripts are intended run by `deno`.

All SDKs are installed under `$HOME`

## env

Only intended for `linux/amd64`.

Some scripts have swtich statements for `windows`, `darwin`, and arch other than `amd64`.

## Dependency

- `xsel`
- `fzf`: https://github.com/junegunn/fzf

## About each config

### nvim

#### Use with `BlexMono Nerd Font`

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

