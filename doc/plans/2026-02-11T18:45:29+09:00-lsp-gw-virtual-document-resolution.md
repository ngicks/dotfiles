# Virtual Document Content Resolution for lsp-gw

## Context

When `textDocument/definition` or `textDocument/references` returns a non-`file://` URI (e.g., `jdt://` for Java JARs), `normalize_location()` calls `vim.uri_to_fname()` which produces a garbage path. LLM agents can't read dependency sources.

The approach: let Neovim handle it. Open the virtual URI as a buffer — Neovim plugins (nvim-jdtls, etc.) register `BufReadCmd` handlers that fill the buffer with decompiled source. Then read the buffer content and return it inline.

## Changes

All changes are in Lua only. No Go/proto changes needed — `toProtoValue` already handles arbitrary maps, and `google.protobuf.Value` is flexible.

### Files to modify
- `tools/lsp-gw/server/lua/lsp_gateway/init.lua` (embedded copy)
- `config/nvim/lua/lsp_gateway/init.lua` (interactive copy, keep in sync)

### 1. Add `is_file_uri(uri)` helper

```lua
local function is_file_uri(uri)
  return uri:sub(1, 7) == "file://"
end
```

### 2. Add `resolve_virtual_uri(uri, timeout_ms)` helper

Strategy (per codex review): `bufload()` may not reliably trigger `BufReadCmd` for non-file URIs. Use `:edit` as the primary approach, which is the standard path URI handler plugins expect.

```lua
local function resolve_virtual_uri(uri, timeout_ms)
  timeout_ms = timeout_ms or 10000
  local bufnr = vim.fn.bufadd(uri)

  -- Record changedtick before triggering load
  local tick_before = vim.api.nvim_buf_get_var(bufnr, "changedtick") or 0

  -- Use :edit to trigger BufReadCmd — this is the path URI handler plugins
  -- (nvim-jdtls, etc.) expect. keepalt/keepjumps avoids side effects.
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd("silent keepalt keepjumps edit " .. vim.fn.fnameescape(uri))
  end)

  -- Poll until changedtick changes (content was written) or timeout.
  -- vim.wait processes events between checks, avoiding RPC starvation.
  local ok = vim.wait(timeout_ms, function()
    local tick = vim.api.nvim_buf_get_var(bufnr, "changedtick") or 0
    return tick ~= tick_before
  end, 50)

  if not ok then return nil end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  if #lines == 0 or (#lines == 1 and lines[1] == "") then
    return nil
  end
  return table.concat(lines, "\n")
end
```

Key points:
- `:edit` via `nvim_buf_call` so handler runs in buffer context without switching current window
- `changedtick` tracking detects actual content writes, not just non-empty lines
- `vim.wait` with 50ms interval processes events properly (no RPC starvation)
- Returns `nil` on timeout — caller still returns the location with raw URI

### 3. Modify `normalize_location(loc)`

- If `file://` URI: behave as before (`vim.uri_to_fname`)
- If non-file URI: call `resolve_virtual_uri`, return `{ filename = uri, line, col, content = resolved_text }`
- `content` field is only present for virtual URIs — no bloat for normal locations

### Response shape (virtual URI)

```json
{
  "ok": true,
  "result": [
    {
      "filename": "deno:/asset/lib.deno.ns.d.ts",
      "line": 1234,
      "col": 2,
      "content": "/** Serves HTTP requests...\nexport function serve(...): HttpServer<...> {\n..."
    }
  ]
}
```

Normal `file://` responses are unchanged (no `content` field).

## Edge cases

- **No URI handler installed**: buffer stays empty, `content` is `nil`/absent. Still better than garbage path.
- **Same URI queried twice**: `bufadd` returns existing buffer (already populated). `changedtick` won't change → timeout, but lines will already be populated → return content immediately (add early-exit check before `:edit`).
- **Buffer accumulation**: acceptable — idle shutdown cleans up the whole Neovim process.
- **Async handlers**: `changedtick` + `vim.wait` handles handlers that populate content asynchronously.
- **Large content**: no truncation for now. gRPC default max message size is 4MB which covers most decompiled classes.

## Verification

1. `go build ./...` — ensure Go still compiles (no Go changes, but rebuild embeds updated Lua)
2. Test with a normal file: `lsp-gw definition some_file.go 10 5` — response should have `file://` location, no `content` field
3. Test with Deno project — go-to-definition on a Deno stdlib symbol (e.g. `Deno.serve`). Deno LSP returns `deno:` URIs for built-in types. The response should include `content` with the resolved type definition source.
