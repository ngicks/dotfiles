# Ctrl+Shift+{h,j,k,l} for Tmux Pane Navigation

## Context

The current tmux.conf bindings (`C-H`, `C-J`, `C-K`, `C-L` on lines 59-62) are intended to be Ctrl+Shift but don't actually work as such. Traditional terminal encoding cannot distinguish `C-h` from `C-H` — both produce the same control character. This means:

- The bindings fire on plain Ctrl+h/j/k/l, hijacking Backspace (C-h), Enter (C-j), and clear-screen (C-l)
- There's no way to have Ctrl+Shift-only bindings without enabling extended key encoding

The fix requires three layers to cooperate: WezTerm (send extended sequences), tmux (parse them), and WezTerm keybinds (stop intercepting).

## Changes

### 1. tmux — `config/tmux/tmux.conf`

**Add** extended-keys support (after line 4, the `terminal-overrides` line):

```tmux
set -s extended-keys on
set -as terminal-features 'xterm*:extkeys'
```

**Replace** lines 59-62 from:

```tmux
bind-key -n C-K select-pane -U
bind-key -n C-J select-pane -D
bind-key -n C-H select-pane -L
bind-key -n C-L select-pane -R
```

To:

```tmux
bind-key -n C-S-k select-pane -U
bind-key -n C-S-j select-pane -D
bind-key -n C-S-h select-pane -L
bind-key -n C-S-l select-pane -R
```

### 2. WezTerm — `config/wezterm/wezterm.lua`

**Add** after line 41 (`config.leader`):

```lua
config.enable_kitty_keyboard = true
```

This enables the kitty keyboard protocol. tmux with `extended-keys on` requests enhanced key reporting, and WezTerm honors it. Non-tmux apps that don't request it are unaffected.

### 3. WezTerm keybinds — `config/wezterm/keybinds.lua`

**Remove** line 56 (conflicts with Ctrl+Shift+K):

```lua
{ key = "k", mods = "SHIFT|CTRL", action = act.ClearScrollback("ScrollbackOnly") },
```

The commented-out SHIFT|CTRL h/j/l lines (84, 86, 88, 90) stay commented — keys must pass through to tmux.

## Verification

1. Reload WezTerm: Ctrl+Shift+R
2. Reload tmux: `prefix + R`
3. Split pane: `prefix + v`
4. Test: Ctrl+Shift+H/J/K/L should navigate panes
5. Verify Ctrl+H (Backspace), Ctrl+J (Enter), Ctrl+L (clear) still work normally in shell
6. Requires tmux 3.2+ (check with `tmux -V`)

## Notes

- Existing Alt-based (M-H/J/K/L) and prefix-based (prefix+h/j/k/l) bindings remain as fallbacks
- WSL2 transport is transparent to keyboard encoding — no extra config needed
- Terminals without kitty keyboard support will simply not fire the C-S- bindings; fallbacks cover that
