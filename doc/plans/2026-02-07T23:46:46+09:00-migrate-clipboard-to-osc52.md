# Migrate Clipboard from xsel to OSC52

## Context

The current dotfiles setup uses `xsel -bi` for clipboard across all tools (tmux, neovim, zellij, lazygit). This requires X11/Wayland and fails in pure SSH or headless scenarios. OSC52 is a terminal escape sequence that lets applications copy text to the host system clipboard through the terminal emulator — it works over SSH, inside tmux, and doesn't require X11/Wayland tooling.

Key preconditions already in place:
- Wezterm supports OSC52 by default
- Tmux already has `allow-passthrough all` set

## Changes

### 1. Tmux — `config/tmux/tmux.conf`

- **Add** `set -g set-clipboard on` (after line 5). This makes tmux emit OSC52 to the outer terminal on any copy operation.
- **Change** line 68: `copy-pipe-and-cancel "xsel -bi"` → `copy-selection-and-cancel`
- **Change** line 69: same for Enter binding

With `set-clipboard on`, tmux itself handles OSC52 emission. `copy-selection-and-cancel` copies to tmux's paste buffer and exits copy mode; the OSC52 sequence is emitted automatically by tmux.

### 2. Neovim — `config/nvim/lua/setup/01_clipboard.lua`

Replace the entire file with:

```lua
vim.g.clipboard = "osc52"
```

This is the documented way to force Neovim's built-in OSC52 clipboard provider (available since v0.10). It replaces both the WSL-specific xsel workaround and the non-WSL `unnamedplus` path. The `unnamedplus` setting in `00_options.lua` (line 10) remains — it controls *when* the clipboard is used (on yank), while `vim.g.clipboard` controls *how*.

Also update **`nix-craft/home/nvim/default.nix`** line 5: remove `xsel xclip` from `extraPackages` → `extraPackages = with pkgs; [ ripgrep fd ];`

### 3. Zellij — `config/zellij/config.kdl`

**Comment out** line 725 (`copy_command "xsel -bi"`). As stated in the config comment on line 717, Zellij uses OSC52 by default when `copy_command` is not set.

### 4. Lazygit — `config/lazygit/config.yml`

Lazygit does **not** support OSC52 natively — without `copyToClipboardCmd` it uses Go's clipboard library (xclip/xsel/pbcopy). To use OSC52, change the command to emit the escape sequence directly:

```yaml
copyToClipboardCmd: printf "\033]52;c;$(printf '{{text}}' | base64 -w 0)\a" > /dev/tty
```

## Files to Modify

| File | Action |
|------|--------|
| `config/tmux/tmux.conf` | Add `set-clipboard on`, change copy bindings to `copy-selection-and-cancel` |
| `config/nvim/lua/setup/01_clipboard.lua` | Replace with `vim.g.clipboard = "osc52"` |
| `nix-craft/home/nvim/default.nix` | Remove `xsel xclip` from extraPackages |
| `config/zellij/config.kdl` | Comment out `copy_command "xsel -bi"` |
| `config/lazygit/config.yml` | Change `copyToClipboardCmd` to OSC52 printf |

## Verification

1. **Tmux**: Enter copy mode (`prefix + [`), select text (`v`), yank (`y`) — text should appear in system clipboard
2. **Neovim**: Yank text (`yy`) — text should appear in system clipboard
3. **Zellij**: Enter scroll mode, select and copy — text should appear in system clipboard
4. **Lazygit**: Copy a commit hash — text should appear in system clipboard
5. **Nested test**: Run neovim inside tmux — yank should still reach system clipboard via OSC52 passthrough
