# Zsh Hook Deduplication Plan

## Problem

When shell configuration scripts are re-sourced, hooks can be registered multiple times:

| File | Pattern | Has Deduplication |
|------|---------|-------------------|
| `config/loginscript/03_wezterm.sh:561-580` | `precmd_functions+=()` | **NO** |
| `config/loginscript/02_gpg.sh:30` | `add-zsh-hook` | Yes (built-in) |
| `config/loginscript/03_tmux.sh:7` | `add-zsh-hook` | Yes (built-in) |

**Critical issue**: Wezterm registers 5 hooks with direct array appends, causing duplicates if re-sourced.

## Solution

Create a utility function for safe hook registration, then update wezterm.sh.

## Implementation

### 1. Create utility file

**File**: `nix-craft/home/zsh/loginscript/00_hook_utils.sh` (new)

```bash
# Safe hook append with deduplication for bash-preexec style arrays
# Usage: safe_hook_append <array_name> <function_name>
safe_hook_append() {
    local array_name="$1"
    local func_name="$2"

    if [[ -n "${ZSH_NAME:-}" ]]; then
        # zsh: check if already in array using (I) subscript flag
        if (( ! ${${(P)array_name}[(I)$func_name]} )); then
            eval "${array_name}+=(\${func_name})"
        fi
    else
        # bash: loop to check
        local -n arr_ref="$array_name"
        local item
        for item in "${arr_ref[@]}"; do
            [[ "$item" == "$func_name" ]] && return 0
        done
        arr_ref+=("$func_name")
    fi
}

# Convenience: register precmd+preexec pair
safe_hook_pair() {
    [[ -n "$1" ]] && safe_hook_append precmd_functions "$1"
    [[ -n "$2" ]] && safe_hook_append preexec_functions "$2"
}
```

### 2. Modify wezterm.sh

**File**: `config/loginscript/03_wezterm.sh` (lines 556-582)

Replace direct array appends with safe wrappers:

```bash
if [[ -z "${WEZTERM_SHELL_SKIP_SEMANTIC_ZONES-}" ]]; then
  if [[ -n "${BLE_VERSION-}" ]]; then
    blehook PRECMD+=__wezterm_semantic_precmd
    blehook PREEXEC+=__wezterm_semantic_preexec
  else
    safe_hook_pair __wezterm_semantic_precmd __wezterm_semantic_preexec
  fi
fi

if [[ -z "${WEZTERM_SHELL_SKIP_USER_VARS-}" ]]; then
  if [[ -n "${BLE_VERSION-}" ]]; then
    blehook PRECMD+=__wezterm_user_vars_precmd
    blehook PREEXEC+=__wezterm_user_vars_preexec
  else
    safe_hook_pair __wezterm_user_vars_precmd __wezterm_user_vars_preexec
  fi
fi

if [[ -z "${WEZTERM_SHELL_SKIP_CWD-}" ]] ; then
  if [[ -n "${BLE_VERSION-}" ]]; then
    blehook PRECMD+=__wezterm_osc7
  else
    safe_hook_append precmd_functions __wezterm_osc7
  fi
fi
```

## Files to Modify

| File | Action |
|------|--------|
| `nix-craft/home/zsh/loginscript/00_hook_utils.sh` | CREATE |
| `config/loginscript/03_wezterm.sh` | MODIFY lines 561-580 |

## Verification

```bash
# After implementation, source twice and check for duplicates:
source ~/.zshrc
source ~/.zshrc
typeset -p precmd_functions | grep -o '__wezterm' | sort | uniq -c
# Each function should appear exactly once

# Apply changes:
./homeenv-install.sh
```
