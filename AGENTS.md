# AGENTS.md

This file provides guidance to LLM cli agents when working with code in this repository.

## Important

- Use context7 for tool specific knowledge.
- If you are not `codex`:
  - In difficult reserach, complex planning, ask `codex` for help using `codex exec`.
- You might be in a restricted enviroment: some commands may fail and some special files may not be present (e.g. `/dev/kvm`).
- Do not assume `perl` is installed in the environment.

## Overview

This repository is dotfiles.

Using combination of `nix` and `mise` to manage tools.
There are also configs, build scripts, management scripts and self-mainteined tools.

## Repository Summary

```
.
├── README.md:          this file
├── agents:             files for LLM agents. skills, subagents, plugins(currently only for Claude Code), etc
│   ├── AGENTS.md
│   ├── agents
│   └── skills
├── build               builder scripts for external tools
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
├── moon.mod.json       moonbit configuration for ./src2 currently migrating deno to moonbi2.
├── moon.pkg.json
├── nix-craft           nix flake configuration
├── scripts             misc scripts
├── src                 deno project for management
├── src2                moonbit project for management, currently migrating from ./src2
└── tools               dir hosts tools including source.
    └── lsp-gw
```

## Commands

### Home Manager

`./home-install.sh` handles `nix run .#home-manager ...`
but `./homeenv-upgrade.sh` doesn't because upgrade results have to be commited before switching home-manager.

```bash
./scripts/homeenv/nix-run-home-manager.sh
```

### Deno Tasks

read `deno.json`

## Architecture Notes

### Shell Startup

Shell startup is layered:

1. Home Manager generates shell config
2. `config/loginscript/*.sh` is loaded
3. `~/.config/env/*.env` is loaded
4. `~/.config/env/*.sh` is loaded
5. the daily update task may run

### tools

#### lsp-gw

- `tools/lsp-gw/` is a standalone Go module
- it provides a Cobra CLI and a daemon for Neovim LSP gateway use cases
- generated protobuf files are committed under `tools/lsp-gw/proto/`

### Agents

- `agents/AGENTS.md`: the template copied into prepared development workspaces
- `agents/agents`: subagents
- `agents/skills/`: skills

## Platform Notes

- Supported systems in the flake: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`
- The bootstrap script’s system package manager update currently supports `apt`
- WSL-related behavior exists in the repo, especially around config sync and terminal setup

## MoonBit Guide

Read `${MOON_HOME:-$HOME/.moon}/AGENTS.md` when working on MoonBit code.
