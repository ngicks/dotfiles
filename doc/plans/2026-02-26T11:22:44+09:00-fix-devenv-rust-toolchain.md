# Fix Rust Toolchain "No such file or directory" in devenv Container

## Context

Running `cargo` (or other Rust tools) inside the devenv container fails with:
```
error: command failed: 'cargo': No such file or directory (os error 2)
```

## Root Cause

The host's Nix-installed `rustup` patches downloaded toolchain binaries with `patchelf`, hardcoding the **host's Nix store glibc** as the ELF interpreter:

```
[Requesting program interpreter: /nix/store/j193mfi0f921y0kfs8vjc1znnr45ispv-glibc-2.40-66/lib/ld-linux-x86-64.so.2]
```

The container has a **different glibc store path** (`/nix/store/i3ibgfskl99qd8rslafbpaa1dmxdzh1z-glibc-2.40-66/`). The host's store path doesn't exist in the container, so the kernel returns `ENOENT` when trying to exec the toolchain binaries.

The existing `/lib64` symlinks in the Containerfile are irrelevant — the patched binaries never reference `/lib64/ld-linux-x86-64.so.2`.

## Solution: Container-native Rust toolchain

Install a Rust toolchain during the container build so it's patched for the container's Nix environment. Stop mounting the host's `RUSTUP_HOME` (toolchain binaries are incompatible). Keep mounting `CARGO_HOME` for shared registry/git caches.

## Changes

### 1. Install Rust toolchain during build — `devenv/Containerfile`

Add `rustup default stable` after home-manager switch. This installs a toolchain patched with the container's Nix store paths. Also remove the now-unnecessary `/lib` symlink attempt (creates wrong `/lib/lib` anyway).

In the final `RUN` block, add:
```bash
RUSTUP_HOME="${XDG_DATA_HOME:-/root/.local/share}/rustup" \
CARGO_HOME="${XDG_DATA_HOME:-/root/.local/share}/cargo" \
  rustup default stable
```

Clean up the glibc symlinks — keep `/lib64` for any other non-Nix binaries, remove broken `/lib` symlink:
```bash
NIX_GLIBC_PATH=$(nix-build '<nixpkgs>' -A glibc --no-out-link)
ln -sfn ${NIX_GLIBC_PATH}/lib64 /lib64
```

### 2. Remove RUSTUP_HOME mount/env — `devenv/scripts/run-devenv.sh`

Remove these lines (54-55 fallback + 118-119 mount/env):
```bash
# Remove:
RUSTUP_HOME=${RUSTUP_HOME:-$HOME/.rustup}

# Remove:
--env RUSTUP_HOME=${RUSTUP_HOME}
--mount type=bind,src=${RUSTUP_HOME},dst=${RUSTUP_HOME}$(ro)
```

Keep `CARGO_HOME` mounting — registry/git caches are data files, not binaries.

### 3. Remove `00_rust.sh` RUSTUP_HOME export — `nix-craft/home/zsh/loginscript/00_rust.sh`

`export_unless_container_override RUSTUP_HOME ...` is no longer needed since RUSTUP_HOME won't be injected from the host. The container's shell init should set RUSTUP_HOME to its local path. Change to:
```bash
export_unless_container_override CARGO_HOME "${XDG_DATA_HOME:-$HOME/.local/share}/cargo"
export RUSTUP_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/rustup"
```

Actually, `export_unless_container_override` for RUSTUP_HOME still makes sense — the container won't have RUSTUP_HOME set externally anymore, so the function will set it to the XDG path. No change needed here.

## Files Modified

- `devenv/Containerfile` — add `rustup default stable`, fix `/lib` symlink
- `devenv/scripts/run-devenv.sh` — remove `RUSTUP_HOME` fallback, env, and mount (lines 55, 118-119)

## Verification

1. Rebuild container with experimental tag
2. Inside the container, verify:
   - `rustup show` — shows container-native toolchain
   - `cargo --version` — works
   - `rustc --version` — works
   - `readelf -l $(which cargo) | grep interpreter` — shows container's Nix store path
3. Verify host crate caches still shared: `ls $CARGO_HOME/registry/`
