# Add MoonBit Devenv Helper Tools (`tools/`)

## Context

LLM agents working in the devenv need small CLI utilities for project navigation and document searching. Two specific tools are needed:

1. **find-root** - Finds project root by walking parent dirs for markers (`.git`, `.claude`, `AGENTS.md`), similar to Neovim's LSP root detection
2. **rg-front-matter** - A `rg --pre` preprocessor that extracts YAML front matter from markdown files, optionally filtering to specific heading fields

These will be written in MoonBit, compiled to WebAssembly (wasm-gc), and run via `moonrun`. The MoonBit toolchain (`moon` CLI) will be installed via the official installer (not yet in nixpkgs).

## New Files

```
tools/                                    # MoonBit module root
  moon.mod.json                           # Module "dotfiles/tools"
  .gitignore                              # Ignore target/, .mooncakes/
  src/
    lib/
      moon.pkg.json                       # Shared library package
      path_utils.mbt                      # Directory traversal utilities
      path_utils_test.mbt                 # Tests
    find_root/
      moon.pkg.json                       # is-main: true, imports lib
      main.mbt                            # Entry: walk parents, check markers
    rg_front_matter/
      moon.pkg.json                       # is-main: true
      main.mbt                            # Entry: extract front matter from file

scripts/tools/
  find-root.sh                            # Wrapper: exec moonrun <wasm> "$@"
  rg-front-matter.sh                      # Wrapper: exec moonrun <wasm> "$@"

scripts/homeenv/
  moonbit-install.sh                      # Install MoonBit toolchain (idempotent)
  moonbit-tools-build.sh                  # Build tools/ WASM artifacts
```

## Modified Files

- **`nix-craft/home/home.nix`** (line 12-15, line 21-24)
  - Add `"$HOME/.moon/bin"` to `home.sessionPath`
  - Add `home.file` entries for wrapper scripts in `~/.local/bin/`
- **`homeenv-install.sh`** (after line 23)
  - Add moonbit-install and moonbit-tools-build steps

## Tool Details

### find-root
- Accepts optional starting path argument (defaults to cwd)
- Walks parent directories checking for markers: `.git`, `.claude`, `AGENTS.md`
- Prints root path to stdout, exits non-zero if not found
- **Filesystem risk**: moonrun's WASI support for directory stat needs verification. If insufficient, implement as a shell fallback within the wrapper script.

### rg-front-matter
- Follows `rg --pre` contract: receives file path as `$1`, reads the file, writes processed content to stdout
- Extracts content between opening and closing `---` markers
- Supports `--fields=tags,created` flag to limit output to specific YAML keys
- Usage: `rg --pre rg-front-matter --pre-glob '*.md' "search-term" ./doc/plans/`

## Wrapper Scripts

Each wrapper uses absolute paths and includes error handling for missing WASM:
```bash
#!/usr/bin/env bash
WASM="$HOME/.dotfiles/tools/target/wasm-gc/release/build/src/find_root/find_root.wasm"
if [[ ! -f "$WASM" ]]; then
  echo "error: WASM not built. Run: scripts/homeenv/moonbit-tools-build.sh" >&2
  exit 1
fi
exec "$HOME/.moon/bin/moonrun" "$WASM" "$@"
```

## MoonBit Toolchain Installation

`scripts/homeenv/moonbit-install.sh`:
- Check if `~/.moon/bin/moon` exists; if yes, run `moon upgrade`
- If not, install via `curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash`
- Clean up any shell RC modifications the installer makes (sed remove `.moon/bin` lines from `.bashrc`/`.zshrc`)
- PATH managed by Home Manager's `home.sessionPath` instead

## Integration into homeenv-install.sh

After the mise-install step (line 23), add:
```bash
echo ""
echo "moonbit install"
echo ""
./scripts/homeenv/moonbit-install.sh
echo ""
echo "moonbit tools build"
echo ""
./scripts/homeenv/moonbit-tools-build.sh
```

## Verification

1. Run `scripts/homeenv/moonbit-install.sh` - confirm `~/.moon/bin/moon version` works
2. Run `cd tools && ~/.moon/bin/moon test` - confirm tests pass
3. Run `scripts/homeenv/moonbit-tools-build.sh` - confirm WASM artifacts created
4. Test `find-root` from a nested directory in the dotfiles repo
5. Test `rg --pre rg-front-matter --pre-glob '*.md' "moonbit" ./doc/plans/`
6. Run full `homeenv-install.sh` end-to-end
