-- tsgo (the ts7 native toolchain) is the LS for non-deno projects.
-- cmd/filetypes/settings come from nvim-lspconfig's lsp/tsgo.lua; project root
-- detection stays the exact complement of denols
-- (see ngcfg.func.switch_ts_ls: single typescript files belong to deno).
-- Library targets reuse the client that returned the navigation result.
return {
  root_dir = function(bufnr, on_dir)
    local switch = require "ngcfg.func.switch_ts_ls"
    if require("ngcfg.func.ts_library").attach_if_library("tsgo", bufnr) then
      return
    end
    local root = switch.find_node_root_dir(bufnr)
    if root ~= nil and root ~= "" then
      on_dir(root)
    end
  end,
}
