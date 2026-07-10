-- Fallback LS for non-deno projects while tsgo (after/lsp/tsgo.lua) proves
-- itself. Attaches only when DOTFILES_NVIM_PREFER_TSLS is set; otherwise tsgo
-- takes the same buffers.
return {
  root_dir = function(bufnr, on_dir)
    local switch = require "ngcfg.func.switch_ts_ls"
    if not switch.prefer_ts_ls() then
      return
    end
    local root = switch.find_node_root_dir(bufnr)
    if root ~= nil and root ~= "" then
      on_dir(root)
    end
  end,
}
