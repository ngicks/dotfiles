---
description: "Basic project guidance"
applyTo: "*"
---

### Project Structure

#### Overview

This repository is dotfiles.

The `nix` and the `mise` are combined to manage tools and libraries.
`NixOS` is not used. Base OS is required and managing it is out-of-scope.
The dotfiles is only tested against `Ubuntu` but I may use this in other environment.
Bascially everything should be able to work with `lixnu/amd64`, `linux/arm64`, `darwin/amd64` and `darwin/arm64`

#### Repository Summary

```
.
├── .apm                apm
├── AGENTS.md
├── LICENSE
├── build               build scripts for external tools (may be migrated to moonbit)
│   ├── krun            krun (crun but krun enabled)
│   └── podman-static   podman-static with my own configuration.
├── config              config files which will be symlinked under ${XDG_CONFIG_HOME:-$HOME/.config}
│   ├── lazygit
│   ├── loginscript     source-d from .zshrc
│   ├── mise
│   ├── nix
│   ├── nvim
│   ├── tmux
│   ├── wezterm
│   └── zellij
├── deno.json           deno project configuration for ./src
├── deno.lock
├── devenv              OCI Image in which LLM can work and related scripts
├── devenv_prep.sh      prep scripts for projects which enable some LLM related tools
├── devenv_run.sh       runner script for the devenv image which wraps lengthy `podman run` invocation
├── homeenv-install.sh  sync current env to dotfiles
├── homeenv-upgrade.sh  update env and dotfiles to latest
├── moon.mod.json       moonbit configuration for ./src2. currently migrating deno to moonbi2.
├── moon.pkg.json
├── nix-craft           nix flake configuration
├── scripts             misc scripts
├── src                 deno project for management
├── src2                moonbit project for management, currently migrating from ./src2
└── tools               dir hosts tools including source. (currently nothing)
```
