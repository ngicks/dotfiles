# Per-Project Neovim Config via Built-in exrc

## Context

There is currently no mechanism to load project-specific Neovim configuration. The `exrc` option is not enabled, and modeline is explicitly disabled. Enabling Neovim's built-in `exrc` feature allows projects to define `.nvim.lua` files that are automatically loaded when Neovim starts in that directory, with a `:trust` security mechanism.

## Changes

### 1. Enable `exrc` in options

**File:** `config/nvim/lua/setup/00_options.lua`

Add at the end of the file:

```lua
-- per-project config: loads .nvim.lua, .nvimrc, or .exrc from cwd
-- requires explicit :trust for each file before it runs
o.exrc = true
```

This is the only change needed. Neovim's built-in `exrc` (available since 0.9):
- Searches for `.nvim.lua`, `.nvimrc`, `.exrc` in the current working directory
- Requires the user to run `:trust <file>` before it will execute an untrusted file
- Trust state is stored in `$XDG_STATE_HOME/nvim/trust`

## Usage

1. Create `.nvim.lua` in a project root with project-specific settings (e.g., tab width, LSP overrides)
2. Open Neovim in that directory
3. On first load, run `:trust .nvim.lua` to approve execution
4. The file will be sourced automatically on subsequent opens

## Verification

1. Run `homeenv-install.sh` or manually symlink configs
2. Create a test `.nvim.lua` in a project directory: `vim.o.tabstop = 4`
3. Open Neovim in that directory
4. Run `:trust .nvim.lua`
5. Verify `:set tabstop?` returns 4
