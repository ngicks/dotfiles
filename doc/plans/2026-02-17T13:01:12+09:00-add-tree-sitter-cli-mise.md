# Plan: Add cargo:tree-sitter-cli to mise.toml

## Context

The user wants to manage `tree-sitter-cli` via mise using the cargo backend. The nvim config already uses nvim-treesitter (recent migration in commit 5517af8), so having the `tree-sitter` CLI available is useful for grammar development and testing.

## Changes

### 1. Add `cargo:tree-sitter-cli` to `config/mise/mise.toml`

Add under `[tools]`, grouped logically (new "Tree-sitter" section):

```toml
# Tree-sitter
"cargo:tree-sitter-cli" = "latest"
```

### 2. Add `cargo-binstall` to `nix-craft/home/home.nix`

The mise cargo backend with `binstall = true` requires `cargo-binstall` in PATH to download prebuilt binaries. Mise invokes `cargo-binstall` directly as a standalone binary (confirmed from `src/backend/cargo.rs`), so `cargo` itself is NOT needed in PATH. Prebuilt linux-x64 binaries exist on tree-sitter GitHub releases.

Add `cargo-binstall` to `home.packages`:

```nix
cargo-binstall  # Prebuilt Rust binary installer (used by mise cargo backend)
```

**Existing deps already cover runtime needs:**
- `gcc` — C compiler (tree-sitter generates/compiles C parsers at runtime via `tree-sitter build`)
- `nodejs` — needed for `tree-sitter generate` (grammar JS execution)

## Files to modify

- `config/mise/mise.toml` — add `"cargo:tree-sitter-cli" = "latest"` under `[tools]`
- `nix-craft/home/home.nix` — add `cargo-binstall` to `home.packages`

## Verification

```bash
# Rebuild home-manager config
cd nix-craft && nix run .#home-manager -- switch -b backup --flake .#default --impure

# Install tree-sitter-cli
mise install cargo:tree-sitter-cli

# Verify
tree-sitter --version
```

## Review

Plan reviewed and approved by codex. Key finding: mise calls `cargo-binstall` standalone (not as cargo subcommand), so no Rust toolchain bootstrapping needed.
