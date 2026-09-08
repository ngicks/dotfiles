-- tsgo (the ts7 native toolchain) is the LS for non-deno projects.
-- cmd/filetypes/settings come from nvim-lspconfig's lsp/tsgo.lua; only root
-- detection is overridden so it stays the exact complement of denols
-- (see ngcfg.func.switch_ts_ls: single typescript files belong to deno).
return {
  root_dir = function(bufnr, on_dir)
    local root = require("ngcfg.func.switch_ts_ls").find_node_root_dir(bufnr)
    if root ~= nil and root ~= "" then
      on_dir(root)
    end
  end,
}
