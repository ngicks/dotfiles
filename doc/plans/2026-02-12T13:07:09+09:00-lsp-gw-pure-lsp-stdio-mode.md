# Add Pure-LSP Stdio Mode to lsp-gw

## Context

lsp-gw currently exposes LSP features via CLI subcommands (`lsp-gw definition file.go 10 5`) that talk to a Go daemon over gRPC, which delegates to headless Neovim. This works for AI agents and scripts, but can't be used as a standard LSP server by editors or tools that expect stdio JSON-RPC.

Adding `lsp-gw lsp` creates a stdio LSP proxy: it reads standard LSP JSON-RPC from stdin, translates to gRPC calls to the existing daemon, and writes LSP responses to stdout. Uses pwd as the default project root, but honors `initialize.params.rootUri` if provided.

## Architecture

```
Editor/tool (stdio JSON-RPC 2.0)  →  lsp-gw lsp  →  gRPC  →  Daemon  →  Neovim  →  Real LSP
```

The daemon must be running (`lsp-gw server start`). The `lsp` command connects to it like any other CLI subcommand.

**Limitation:** Neovim reads files from disk. In-memory edits (`textDocument/didChange`) are not reflected — only saved files are visible. This is acceptable for the primary use case (AI tool integration) and documented in capabilities (`change: 0 / None`).

## Files

| File | Action |
|------|--------|
| `tools/lsp-gw/lsp/server.go` | **New** — Server struct, stdio read loop, dispatch, response writing |
| `tools/lsp-gw/lsp/protocol.go` | **New** — JSON-RPC 2.0 types + Content-Length framing (read/write) |
| `tools/lsp-gw/lsp/handler.go` | **New** — Per-method handlers, translate LSP params → gRPC → LSP results |
| `tools/lsp-gw/cmd/lsp.go` | **New** — Cobra command: resolve project, dial daemon, run server |
| `tools/lsp-gw/cmd/root.go` | **Modify** — Add `newLspCmd()` to `rootCmd.AddCommand(...)` |

## Design Details

### 1. `lsp/protocol.go` — JSON-RPC 2.0 framing

Types: `Request`, `Response`, `ResponseError`. No external dependencies.

```go
func ReadMessage(r *bufio.Reader) ([]byte, error)
func WriteMessage(w io.Writer, v any) error
```

**`ReadMessage`**: Read headers line by line until `\r\n`. Parse `Content-Length` (case-insensitive). Tolerate and ignore other headers (`Content-Type`, etc.). Read exactly N bytes of body.

**`WriteMessage`**: Marshal to JSON, write `Content-Length: N\r\n\r\n` + body.

### 2. `lsp/server.go` — Main loop

```go
type Server struct {
    handler  *Handler
    reader   *bufio.Reader
    writer   io.Writer
    mu       sync.Mutex   // serialize writes to stdout
    shutdown bool         // set by shutdown request
}
```

Loop: `ReadMessage` → unmarshal base `{id, method}` → if `id != nil` it's a request (dispatch, send response), else it's a notification (dispatch, no response).

- Pre-initialize requests (except `initialize`) → `ServerNotInitialized` error (-32002)
- Unknown requests → `MethodNotFound` error (-32601)
- Unknown notifications → silently ignored (per LSP spec)
- `exit` notification → `os.Exit(0)` if `shutdown` was received, `os.Exit(1)` otherwise
- `$/cancelRequest` → silently ignored (all requests are synchronous)

### 3. `lsp/handler.go` — Method handlers + translation

Single `Handler` struct holds `pb.LspGatewayClient`, `project string`, and `initialized bool`.

**Lifecycle:**
- `initialize` → set `initialized = true`. If `params.rootUri` is set (and not empty), override `project` with it. Return `{capabilities, serverInfo}`.
- `initialized` → no-op notification
- `shutdown` → set server `shutdown = true`, return null
- `exit` → handled by server loop

**Document sync (no-ops — neovim reads from disk):**
- `textDocument/didOpen`, `textDocument/didClose`, `textDocument/didSave`, `textDocument/didChange`

**Queries — translate LSP → gRPC → LSP:**

| LSP method | gRPC call | Response translation |
|------------|-----------|---------------------|
| `textDocument/definition` | `GetDefinition(LocationRequest)` | `[{filename,line,col}]` → `Location[]` |
| `textDocument/references` | `GetReferences(LocationRequest)` | same as above |
| `textDocument/hover` | `GetHover(LocationRequest)` | `string` → `{contents: {kind:"markdown", value:...}}` |
| `textDocument/documentSymbol` | `GetDocumentSymbols(FileRequest)` | `[{name,kind,start_line,end_line}]` → `DocumentSymbol[]` |
| `textDocument/diagnostic` | `GetDiagnostics(FileRequest)` | `[{line,col,severity,message,source}]` → `{kind:"full", items: Diagnostic[]}` |

**Translation details:**

- **URI handling**: Use `net/url` for proper parsing. `url.Parse(uri)` → `url.Path` to get the filesystem path (handles `file:///path` and percent-encoding). When returning locations, construct `file://` + path. Non-file URIs from virtual docs (jdt://, deno://) pass through as-is.
- **Positions**: Pass through directly — both LSP and the Lua module use 0-indexed line/character. Advertise `positionEncoding: "utf-16"` in capabilities (LSP default, matches Neovim's LSP client).
- **Protobuf → JSON**: The daemon's `QueryResponse.Result` is a `google.protobuf.Value`. Use `protojson.Marshal` then `json.Unmarshal` to get plain `map[string]any`, then restructure into LSP shapes. Watch for `float64` from JSON unmarshaling — cast to `int` for line/col fields.
- **Diagnostic ranges**: Set `end` = `start` (same position) since the Lua module only returns a single point. This is valid per LSP spec.
- **Error mapping**: When `QueryResponse.Ok == false`, return a JSON-RPC error (`InternalError` -32603) with the error message, not a successful result.

**Server capabilities advertised in `initialize`:**

```go
map[string]any{
    "positionEncoding": "utf-16",
    "textDocumentSync": map[string]any{
        "openClose": true,
        "change":    0, // None
    },
    "definitionProvider":     true,
    "referencesProvider":     true,
    "hoverProvider":          true,
    "documentSymbolProvider": true,
    "diagnosticProvider": map[string]any{
        "interFileDependencies": false,
        "workspaceDiagnostics":  false,
    },
}
```

### 4. `cmd/lsp.go` — Cobra command

```go
func newLspCmd() *cobra.Command {
    // Use: "lsp", Short: "Run as stdio LSP server"
    // Args: cobra.NoArgs
    // RunE:
    //   log.SetOutput(os.Stderr)  // stdout is protocol
    //   project = resolveProject()  // pwd or --project flag (overridden by initialize rootUri)
    //   conn, client = dialDaemon(resolveDaemonSocket())
    //   lsp.NewServer(client, project).Run(cmd.Context())
}
```

### 5. `cmd/root.go` — Register command

Add `newLspCmd()` to `rootCmd.AddCommand(...)` on line 37.

## Verification

1. `cd tools/lsp-gw && go build ./...` — compiles
2. Start daemon: `lsp-gw server start &`
3. Manual stdio test (pipe JSON-RPC):
   ```
   echo -ne 'Content-Length: 52\r\n\r\n{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | lsp-gw lsp --project /some/project
   ```
   — should get back a Content-Length framed response with capabilities
4. Test with an LSP client (e.g., Neovim `vim.lsp.start({cmd={'lsp-gw','lsp'}})`)
