# Plan: Remove Mason Dependency from Neovim Config

## Context

Mason (neovim package manager for LSP servers, formatters, DAP adapters) adds a redundant tool management layer when Nix Home Manager and Mise already handle tool installation. This creates:
- Duplicate installations (e.g., gopls in both Mason and Mise)
- Fragile Mason-specific directory paths for DAP adapters
- An extra update surface to maintain

Goal: Remove all Mason plugins and move every tool to Nix or Mise, with Mason's auto-install/PATH logic removed entirely.

## Migration Mapping

### LSP Servers → Nix (`home.packages`)

| Server | Nix Package |
|--------|-------------|
| `lua_ls` | `lua-language-server` |
| `html` + `cssls` + `jsonls` | `vscode-langservers-extracted` (includes vscode-json-language-server) |
| `marksman` | `marksman` |
| `taplo` | `taplo` |
| `pyright` | `pyright` |
| `clangd` | Already on PATH; no change needed |
| `ts_ls` | `typescript-language-server` + `typescript` (peer dep) |
| `rust_analyzer` | `rust-analyzer` (add to Nix as fallback; `rustup` may or may not have it installed) |
| `denols` | Comes with `deno`; already in Nix |
| `gopls` | Already in Mise |
| `golangci_lint_ls` | Already in Mise |

### Formatters/Linters → Nix

| Tool | Nix Package | Used by |
|------|-------------|---------|
| `kdlfmt` | `kdlfmt` | conform.nvim |
| `prettier` | `prettier` | conform.nvim (css, html, markdown, json) |
| `stylua` | `stylua` | conform.nvim (lua) |
| `xmlformatter` | `xmlformat` | conform.nvim (xml) |
### Go tools → Mise (add to `mise.toml`)

| Tool | Mise entry |
|------|-----------|
| `gomodifytags` | `"go:github.com/fatih/gomodifytags" = "latest"` |
| `impl` | `"go:github.com/josharian/impl" = "latest"` |
| `iferr` | `"go:github.com/koron/iferr" = "latest"` |

Already in Mise (no change): `delve`, `gotests`, `goimports`

### DAP Adapters

| Adapter | Change |
|---------|--------|
| Go (delve) | No change — uses `dlv` on PATH from Mise |
| Node.js (`node-debug2`) | Replace deprecated `node-debug2` with `vscode-js-debug` from Nix; update DAP config to use `pwa-node` adapter |

## Implementation Steps

### 1. Add packages to Nix

**File: `nix-craft/home/home.nix`** — add to `home.packages`:

```nix
# LSP Servers
lua-language-server
vscode-langservers-extracted  # html, cssls, jsonls (includes vscode-json-language-server)
marksman
taplo
pyright
typescript-language-server
typescript                    # peer dep for ts_ls
rust-analyzer                 # fallback if rustup toolchain doesn't include it

# Formatters / Linters
kdlfmt
prettier
stylua
xmlformat                     # nixpkgs name for xmlformatter

# DAP
vscode-js-debug               # provides `js-debug` binary (dapDebugServer.js wrapper)
```

### 2. Add Go tools to Mise

**File: `config/mise/mise.toml`** — add under `[tools]`:

```toml
# Go tools
"go:github.com/fatih/gomodifytags" = "latest"
"go:github.com/josharian/impl" = "latest"
"go:github.com/koron/iferr" = "latest"
```

### 3. Remove Mason plugins from Neovim

**File: `config/nvim/lua/plugins/list.lua`**

Remove these entries:
- `mason-org/mason.nvim` (lines 80-83)
- `williamboman/mason.nvim` (lines 137-141)
- `williamboman/mason-lspconfig.nvim` (lines 142-146)
- `WhoIsSethDaniel/mason-tool-installer.nvim` (lines 147-151)
- `jay-babu/mason-nvim-dap.nvim` (lines 168-172)

Update `nvim-dap` entry to remove `dependencies = { "williamboman/mason.nvim" }`.

### 4. Remove Mason PATH injection

**File: `config/nvim/lua/setup/00_options.lua`**

Delete lines 54-58 (Mason bin PATH addition).

### 5. Simplify `config/ls.lua`

**File: `config/nvim/lua/config/ls.lua`**

Remove `serverIndependentTools`, `get_tools()`, and the `tools` key from the return table. Only keep `lsp = get_servers()`. Add `"jsonls"` to `nonCustomizedServers` list (binary provided by `vscode-langservers-extracted`).

### 6. Clean up `ls-tools/*.lua` — remove `M.tool` tables

**File: `config/nvim/lua/config/ls-tools/go.lua`** — remove `M.tool` table, keep `M.dap`.

**File: `config/nvim/lua/config/ls-tools/java.lua`** — delete entirely (Java tooling dropped).

**File: `config/nvim/lua/config/ls-tools/typescript.lua`** — remove `M.tool` (already empty). Replace deprecated `node-debug2` adapter with `vscode-js-debug` (pwa-node). The Nix package `vscode-js-debug` provides a `js-debug` binary (not `js-debug-adapter`):
```lua
dap.adapters["pwa-node"] = {
  type = "server",
  host = "localhost",
  port = "${port}",
  executable = {
    command = "js-debug",  -- from nixpkgs vscode-js-debug
    args = { "${port}" },
  },
}
```
Update `dap.configurations.javascript` and `.typescript` to use `type = "pwa-node"`.

### 7. Uncomment DAP config loading in nvim-dap

**File: `config/nvim/lua/plugins/config/mfussenegger/nvim-dap/init.lua`**

Uncomment lines 44-49 to re-enable DAP configuration loading from `ls-tools/`:
```lua
local loaded = require("func.scan_conf_dir").load_local_dir("config/ls-tools", true)
for _, ent in ipairs(loaded) do
  if ent.dap then
    ent.dap()
  end
end
```

### 8. Delete Mason plugin config directories

Remove:
- `config/nvim/lua/plugins/config/mason-org/` (entire directory)
- `config/nvim/lua/plugins/config/williamboman/` (entire directory)
- `config/nvim/lua/plugins/config/WhoIsSethDaniel/` (entire directory)
- `config/nvim/lua/plugins/config/jay-babu/` (entire directory)

### 9. Clean up lazy-lock.json

Run `:Lazy sync` in Neovim after all changes. This will auto-remove Mason entries from `lazy-lock.json`.

## Verification

1. Run `homeenv-install.sh` to install all new Nix packages
2. Run `mise install` to install new Go tools
3. Verify binaries are on PATH: `which lua-language-server gopls taplo marksman pyright typescript-language-server rust-analyzer js-debug kdlfmt prettier stylua vscode-json-language-server`
4. Open Neovim, run `:Lazy sync`
5. Open files for each language and verify `:LspInfo` shows server attached:
   - `.lua` → lua_ls
   - `.ts` → ts_ls / denols
   - `.go` → gopls
   - `.py` → pyright
   - `.rs` → rust_analyzer
   - `.toml` → taplo
   - `.md` → marksman
   - `.html` → html
   - `.css` → cssls
   - `.json` → jsonls
6. Test DAP: set breakpoint in a Go file, run `:DapContinue`
7. Confirm no Mason references remain: `rg -n mason config/nvim/` (includes `lazy-lock.json`)

## Critical Files

- `nix-craft/home/home.nix` — add packages
- `config/mise/mise.toml` — add Go tools
- `config/nvim/lua/plugins/list.lua` — remove Mason plugin entries
- `config/nvim/lua/setup/00_options.lua` — remove Mason PATH
- `config/nvim/lua/config/ls.lua` — simplify (remove tools)
- `config/nvim/lua/config/ls-tools/go.lua` — remove M.tool
- `config/nvim/lua/config/ls-tools/java.lua` — delete entirely
- `config/nvim/lua/config/ls-tools/typescript.lua` — replace node-debug2 with js-debug-adapter
- `config/nvim/lua/plugins/config/mfussenegger/nvim-dap/init.lua` — uncomment DAP loading
