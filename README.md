# dotfiles

## env

Only intended for `linux/amd64` and when it have `/bin/bash`.

Some scripts have swtich statements for `windows`, `darwin`, and arch other than `amd64`.

## isntall prerequisites

```
sudo apt update && sudo apt install -y make build-essential gcc clang xsel p7zip-full jq

# dasel is also used in sdk installation. maybe I'll later remove this dependency.
mkdir -p ~/bin
pushd ~/bin
curl -L https://github.com/TomWright/dasel/releases/download/v2.8.1/dasel_linux_amd64.gz -o dasel.gz
gzip -d ./dasel.gz
chmod +x dasel
popd
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

## source .bashrc again

```
. ~/.bashrc
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
