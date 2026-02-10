# lsp-gw: Go CLI for Neovim LSP Gateway

## Context

A Go CLI tool (`lsp-gw`) that uses a persistent headless Neovim instance as an LSP gateway. It connects to the Neovim server via `github.com/neovim/go-client` over Unix sockets, calls Lua gateway functions via `ExecLua`, and returns JSON results. Per-project servers ensure LSP root detection works correctly.

## Architecture

```
Claude Code / User
    │ CLI invocation
    ↓
lsp-gw (Go binary)
    │ nvim.Dial() + ExecLua()
    ↓
Neovim Server (nvim --headless --listen ${XDG_RUNTIME_DIR:-/tmp}/lsp-gw/${sha256}.sock)
    │ vim.lsp.buf_request_sync()
    ↓
Language Server (gopls, ts_ls, etc.)
```

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Line/col indexing | 0-indexed | Match LSP protocol. Programmatic callers (Claude Code) are the primary users. |
| File opening | Auto per query | Each query auto-calls `open_file()` + `wait_for_client()` internally. |
| Exit codes | Always 0 | JSON `ok` field is the only error indicator. Simpler for JSON consumers. |
| Nix install | `home.packages` via `buildGoModule` | Standard Nix pattern. Requires `vendorHash`. |
| Socket path | `${XDG_RUNTIME_DIR:-/tmp}/lsp-gw/${sha256(path)}.sock` | Per-project server. SHA256 of project root path. Configurable via `--socket`/`LSP_GW_SOCKET`. |
| Diagnostics API | `vim.diagnostic.get()` | Neovim's built-in API, not LSP `textDocument/diagnostic` (not universally supported). |
| Server scope | Per-project instance | One server per project root. `stop` stops the server for the current/specified project. |
| nvim config path | `~/.config/nvim/init.lua` | Managed by Home Manager `xdg.configFile` in this repo. |

## Files to Create

### Go module — `tools/lsp-gw/`

| File         | Purpose                                                              |
| ------------ | -------------------------------------------------------------------- |
| `go.mod`     | Module definition, depends on `github.com/neovim/go-client`          |
| `main.go`    | CLI entry point, arg parsing, command dispatch                       |
| `gateway.go` | Neovim RPC client: `Connect()`, `QueryGateway()` via `ExecLua`       |
| `server.go`  | Server lifecycle: `Start()`, `Stop()`, `Status()`, `EnsureRunning()` |
| `lua.go`     | Lua code string builders for each gateway command                    |

### Lua server module — `config/nvim/lua/lsp_gateway/init.lua`

Functions:
- `open_file(filepath, timeout_ms)` — `bufadd` + `bufload` + fire `BufReadPost`/`FileType` autocmds
- `wait_for_client(bufnr, timeout_ms)` — poll `vim.lsp.get_clients({bufnr})` with capped retries
- `get_definition(filepath, line, col)` — `textDocument/definition` via `buf_request_sync`
- `get_references(filepath, line, col)` — `textDocument/references` via `buf_request_sync`
- `get_hover(filepath, line, col)` — `textDocument/hover` via `buf_request_sync`
- `get_document_symbols(filepath)` — `textDocument/documentSymbol` via `buf_request_sync`
- `get_diagnostics(filepath)` — `vim.diagnostic.get(bufnr)` (NOT LSP textDocument/diagnostic)
- `health()` — server health: PID, buffer count, active LSP clients

All return pure string-keyed tables: `{ok = true, result = ...}` or `{ok = false, error = "msg"}`.

### Nix package — `nix-craft/pkgs/lsp-gw.nix`

`buildGoModule` with local `src = ../../tools/lsp-gw`. Add to `home.packages` in `home.nix`.

### Claude Code skill — `.claude/skills/nvim-lsp/SKILL.md`

Update to reference `lsp-gw` binary.

## CLI Design

```
lsp-gw [--socket <path>] [--project <path>] <command> [args...]

Commands:
  definition <filepath> <line> <col>    # textDocument/definition
  references <filepath> <line> <col>    # textDocument/references
  hover <filepath> <line> <col>         # textDocument/hover
  symbols <filepath>                    # textDocument/documentSymbol
  diagnostics <filepath>                # vim.diagnostic.get
  health                                # server health check
  server start|stop|status              # server lifecycle
```

- Socket resolution: `--socket` flag > `LSP_GW_SOCKET` env > `${XDG_RUNTIME_DIR:-/tmp}/lsp-gw/${sha256(project_root)}.sock`
- Project root detection: `git rev-parse --show-toplevel`, fallback to `pwd`. Override with `--project <path>`.
- Line/col are **0-indexed** (match LSP protocol)
- All output is JSON to stdout. **Exit code always 0.** Errors indicated by `{"ok": false, "error": "..."}`
- Diagnostic messages (e.g. "starting server...") go to stderr only
- Auto-starts server on first query via `EnsureRunning()`
- Each query command auto-calls `open_file()` + `wait_for_client()` on the server before the LSP request

## Key Implementation Details

### gateway.go

- **Connect:** `nvim.Dial(socket)` with 5s timeout. If the go-client version doesn't support timeout on Dial, use `net.DialTimeout("unix", socket, 5s)` → `nvim.New(conn)` as fallback.
- **ExecLua:** Pass arguments via `ExecLua` variadic args (maps to Lua `...`) instead of string interpolation. This avoids filepath quoting bugs.
  ```go
  client.ExecLua(`return require('lsp_gateway').get_definition(...)`, &result, filepath, line, col)
  ```
- **Result decoding:** msgpack maps Lua tables differently:
  - String-keyed → `map[string]interface{}`
  - Array-like → `[]interface{}`
  - Mixed keys → `map[interface{}]interface{}`
  - Write a `normalizeResult()` helper that recursively converts `map[interface{}]interface{}` to `map[string]interface{}`

### server.go

- **Start():** Resolve project root (`git rev-parse --show-toplevel` or `pwd`), compute SHA256 of the absolute path, create socket dir `${XDG_RUNTIME_DIR:-/tmp}/lsp-gw/` if needed. Check socket via `net.DialTimeout("unix", socket, 1s)`. If connectable, already running. If socket file exists but not connectable, remove stale file. Spawn `nvim --headless -u ~/.config/nvim/init.lua --listen <socket>` with `Setsid: true` and cwd set to project root. **Readiness: RPC handshake loop** (`ExecLua("return 1")` with 200ms backoff, up to 10s) — not just socket file existence.
- **Stop():** `client.Command("qa!")` + 3s grace period. If process still alive, `SIGTERM`. Clean socket file.
- **EnsureRunning():** Try `net.DialTimeout` first → only spawn if fails. The CLI is short-lived, so "already connected" means "socket accepts connections," not "this process has a cached client."
- **Stale detection:** Socket file exists but `net.DialTimeout` fails = stale. Remove and re-spawn.

### lua.go

- Build Lua code strings for `ExecLua`. Use `...` varargs pattern so Go passes args separately.
- Each command string is a one-liner: `return require('lsp_gateway').get_definition(...)`

### Lua module contract

All gateway functions must return **pure string-keyed tables** for consistent msgpack → Go decoding:
```lua
return {ok = true, result = {...}}   -- result arrays use integer keys (fine, decodes to []interface{})
return {ok = false, error = "msg"}   -- never mixed key types in a single table
```

Location results normalized to: `{filename = "/abs/path", line = 0, col = 0}` (0-indexed).

## Nix Integration

Create `nix-craft/pkgs/lsp-gw.nix`:
```nix
{ lib, buildGoModule }:
buildGoModule {
  pname = "lsp-gw";
  version = "0.1.0";
  src = ../../tools/lsp-gw;
  vendorHash = ""; # Set after first build attempt
  meta.mainProgram = "lsp-gw";
}
```

Add to `home.packages` in `nix-craft/home/home.nix`.

`vendorHash` workflow: Run `nix build`, capture hash from error, update the file.

## Implementation Order

1. Go module: `go.mod` + `lua.go` + `gateway.go` + `server.go` + `main.go`
2. Lua server module: `config/nvim/lua/lsp_gateway/init.lua`
3. Build and test: `go build && ./lsp-gw server start && ./lsp-gw health`
4. Update `.claude/skills/nvim-lsp/SKILL.md`
5. Nix package: `nix-craft/pkgs/lsp-gw.nix` + `home.nix`

## Verification

```bash
# Build
cd tools/lsp-gw && go build -o lsp-gw .

# Server lifecycle (run from a git project directory)
./lsp-gw server start
./lsp-gw server status
./lsp-gw health

# LSP queries (use a real project file with a configured LSP)
./lsp-gw symbols /path/to/some/file.go
./lsp-gw definition /path/to/some/file.go 10 5
./lsp-gw references /path/to/some/file.go 10 5
./lsp-gw hover /path/to/some/file.go 10 5
./lsp-gw diagnostics /path/to/some/file.go

# Cleanup
./lsp-gw server stop
```

Note: First query on a file will be slow (~2-5s) as the LSP server starts and indexes. Subsequent queries on the same file should be ~50-200ms.
