# dotfiles

## env

Only intended for `linux/amd64` and when it have `/bin/bash`.

Some scripts have swtich statements for `windows`, `darwin`, and arch other than `amd64` but they are totally WIP stubs.
Currently no other platforms are supported.

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

### libs

```
./install_dependencies.sh
```

## install SDK

First, install SDKs by `./install_sdk.sh`

All other scripts are intended run by `deno`.

All SDKs are installed under `$HOME`

## install dotfiles

After installation of SDKs, call `install` tasks.

At this point, PATH is not modified so call deno directly.

```
~/.deno/bin/deno task install
```

## set up configs under ~/.config/env

```shell
export ZSH_THEME="obraun"
```

## source .bashrc again

```
. ~/.bashrc

# or

. ~/.zshrc
```

## install jdk(OPTIONAL)

download and places opnenjdk distributions.

All JDKs are installed under `~/.local/openjdk`

```
deno task jdk:install
```

The task `jdk:dotenv` prints `JAVA9_HOME=/path/to/that/version`

```
deno task jdk:dotenv >> ~/.config/env/jdk.env
```

Later create of modify `~/.config/env/jdk.sh`

All `*.sh` files are loaded after `*.env` files so you can safely use.

```
#!/bin/bash

export JAVA_HOME=$JAVA24_HOME
export PATH=$JAVA_HOME/bin:$PATH
export GRADLE_USER_HOME=$HOME/.cache/gradle

```

## About each config

### nvim

#### Use with `BitstromWera Nerd Font Mono`

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
