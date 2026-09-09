-- tsgo (the ts7 native toolchain) is the LS for non-deno projects.
-- cmd/filetypes/settings come from nvim-lspconfig's lsp/tsgo.lua; only root
-- detection is overridden so it stays the exact complement of denols
-- (see ngcfg.func.switch_ts_ls: single typescript files belong to deno).
-- Jump targets inside node_modules or the bundled lib.*.d.ts reuse the client
-- of the buffer the jump came from instead of starting a server there.
return {
  root_dir = function(bufnr, on_dir)
    local switch = require "ngcfg.func.switch_ts_ls"
    if switch.attach_origin_client_if_library("tsgo", bufnr) then
      return
    end
    local root = switch.find_node_root_dir(bufnr)
    if root ~= nil and root ~= "" then
      on_dir(root)
    end
  end,
}
