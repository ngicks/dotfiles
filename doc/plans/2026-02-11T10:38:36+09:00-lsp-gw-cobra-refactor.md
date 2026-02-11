# lsp-gw: Cobra Refactor + Subpackages + Runtime Lua Injection

## Context

`tools/lsp-gw/` is a Go CLI that uses a headless Neovim as an LSP gateway. Currently all code lives in `package main` with manual flag/command parsing. The Lua plugin at `config/nvim/lua/lsp_gateway/init.lua` must be present in the user's neovim config for it to work. This refactoring addresses three goals:

1. Use cobra for clean subcommand routing
2. Move logic into subpackages, keeping `main.go` minimal
3. Embed the Lua plugin in the binary and inject it at runtime via `rtp` prepend, so lsp-gw works with any neovim config

## New Directory Structure

```
tools/lsp-gw/
├── main.go                              # Signal setup + cmd.Execute()
├── go.mod / go.sum
├── cmd/
│   ├── root.go                          # Root cobra command + persistent flags + output helpers
│   ├── server.go                        # server start|stop|status
│   ├── definition.go                    # definition command
│   ├── references.go                    # references command
│   ├── hover.go                         # hover command
│   ├── symbols.go                       # symbols command
│   ├── diagnostics.go                   # diagnostics command
│   └── health.go                        # health command
├── gateway/
│   └── gateway.go                       # Connect, QueryGateway, NormalizeResult
├── server/
│   ├── server.go                        # SocketDir, ProjectSocket, DetectProjectRoot, lifecycle
│   ├── lua.go                           # go:embed + PrepareLuaRuntime/CleanupLuaRuntime
│   └── lua/lsp_gateway/init.lua         # Embedded Lua (copied from config/nvim/)
```

## Cobra Command Tree

```
lsp-gw [--socket PATH] [--project PATH]
├── server start
├── server stop
├── server status
├── health
├── definition <filepath> <line> <col>
├── references <filepath> <line> <col>
├── hover <filepath> <line> <col>
├── symbols <filepath>
└── diagnostics <filepath>
```

- `LSP_GW_SOCKET` env var still supported (checked in `resolveSocketAndProject`)
- Query commands use `cobra.ExactArgs(3)` or `cobra.ExactArgs(1)`
- `SilenceUsage: true` + `SilenceErrors: true` on root to preserve JSON-only output contract

## Runtime Lua Injection

**Approach**: runtimepath prepend (preserves `require()` semantics)

1. `server/lua.go` uses `//go:embed lua/lsp_gateway/init.lua` to embed the Lua source
2. `PrepareLuaRuntime()` writes the embedded file to `<tmpdir>/lua/lsp_gateway/init.lua`
3. `StartServer()` launches nvim with `--cmd "set rtp^=<tmpdir>"` to prepend our Lua to the runtimepath
4. User's neovim config still loads normally (LSP servers get configured), but `require('lsp_gateway')` resolves to our embedded version
5. Cleanup: `StopServer()` reads sidecar file `<socket>.luadir` and removes the temp dir

**Key**: No `-u NONE` — the user's LSP config must load for LSP servers to work.

### Codex Review Notes (addressed)

- **Spaces in tmpdir**: Use `fnameescape()` — `--cmd "execute 'set rtp^=' . fnameescape('<tmpdir>')"`
- **Sidecar write order**: Write `<socket>.luadir` sidecar **before** launching nvim; handle missing sidecar gracefully in `StopServer`
- **Cobra error contract**: Every `RunE` must call `outputError()` and return `nil` — never return a raw error to cobra
- **Embedded file must be committed**: The `server/lua/lsp_gateway/init.lua` file must be in git for `go:embed` to work at build time
- **Two-copy divergence**: Add a comment in both Lua files noting the other copy exists

## Implementation Steps

1. **Create embedded Lua**: Copy `config/nvim/lua/lsp_gateway/init.lua` → `tools/lsp-gw/server/lua/lsp_gateway/init.lua`
2. **Create `gateway/gateway.go`**: Extract `Connect`, `QueryGateway`, `normalizeResult` (export as `NormalizeResult`) from current `gateway.go`
3. **Create `server/lua.go`**: `go:embed` directive + `PrepareLuaRuntime()`/`CleanupLuaRuntime()`
4. **Create `server/server.go`**: Extract from current `server.go`. Modify `StartServer` to call `PrepareLuaRuntime()` and pass `--cmd "execute 'set rtp^=' . fnameescape('<tmpdir>')"`. Write sidecar before launch. Modify `StopServer` to clean up lua dir via sidecar.
5. **Add cobra**: `go get github.com/spf13/cobra@latest`
6. **Create `cmd/`**: `root.go` (root command + flags + output helpers), `server.go`, `definition.go`, `references.go`, `hover.go`, `symbols.go`, `diagnostics.go`, `health.go`
7. **Rewrite `main.go`**: Signal setup (context with os.Signal) + `cmd.NewRootCmd().ExecuteContext(ctx)`
8. **Delete old files**: `gateway.go`, `server.go`, `lua.go` at top level
9. **Keep `config/nvim/lua/lsp_gateway/`**: Retained for interactive neovim use (two copies maintained)
10. **Update deps**: `go mod tidy`
11. **Update `nix-craft/pkgs/lsp-gw.nix`**: New `vendorHash` after cobra dependency added

## Files to Modify/Create

- `tools/lsp-gw/main.go` — rewrite (signal setup + delegate)
- `tools/lsp-gw/gateway/gateway.go` — new (extract from gateway.go)
- `tools/lsp-gw/server/server.go` — new (extract from server.go + lua injection)
- `tools/lsp-gw/server/lua.go` — new (embed + runtime helpers)
- `tools/lsp-gw/server/lua/lsp_gateway/init.lua` — new (copy from config/nvim/)
- `tools/lsp-gw/cmd/root.go` — new (root command + flags + output helpers)
- `tools/lsp-gw/cmd/server.go` — new
- `tools/lsp-gw/cmd/definition.go` — new
- `tools/lsp-gw/cmd/references.go` — new
- `tools/lsp-gw/cmd/hover.go` — new
- `tools/lsp-gw/cmd/symbols.go` — new
- `tools/lsp-gw/cmd/diagnostics.go` — new
- `tools/lsp-gw/cmd/health.go` — new
- `tools/lsp-gw/go.mod` — update (add cobra)
- `nix-craft/pkgs/lsp-gw.nix` — update vendorHash

## Files to Delete

- `tools/lsp-gw/gateway.go`
- `tools/lsp-gw/server.go`
- `tools/lsp-gw/lua.go`

Note: `config/nvim/lua/lsp_gateway/init.lua` is kept for interactive neovim use. The Go-embedded copy at `server/lua/lsp_gateway/init.lua` is the version used by the CLI.

## Verification

1. `cd tools/lsp-gw && go build -o lsp-gw .` — must compile
2. `./lsp-gw --help` — shows cobra help with all subcommands
3. `./lsp-gw server start` — starts headless nvim with rtp injection
4. `./lsp-gw health` — returns JSON with ok/pid/lsp_clients
5. `./lsp-gw server stop` — stops server and cleans up lua temp dir
6. Verify temp dir is removed after stop
7. Update nix hash with `nix-update-hash` skill
