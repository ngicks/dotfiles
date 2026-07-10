-- tsgo (typescript-go, the ts7 native toolchain) is the default LS for
-- non-deno projects; set DOTFILES_NVIM_PREFER_TSLS to fall back to ts_ls.
-- cmd/filetypes/settings come from nvim-lspconfig's lsp/tsgo.lua; only root
-- detection is overridden so it stays the exact complement of denols
-- (see ngcfg.func.switch_ts_ls: single typescript files belong to deno).
return {
  root_dir = function(bufnr, on_dir)
    local switch = require "ngcfg.func.switch_ts_ls"
    if switch.prefer_ts_ls() then
      return
    end
    local root = switch.find_node_root_dir(bufnr)
    if root ~= nil and root ~= "" then
      on_dir(root)
    end
  end,
}
