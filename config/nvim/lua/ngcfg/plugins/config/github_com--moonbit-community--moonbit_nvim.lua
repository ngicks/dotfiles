---@type NgPackPluginConfigModule
local M = {}

local root_markers = { "moon.mod.json", "moon.mod" }

M.opts = {
  treesitter = {
    enabled = true,
    auto_install = true,
  },
  lsp = {
    native = true,
    root_markers = root_markers,
    root_dir = function(bufnr, on_dir)
      local root = vim.fs.root(bufnr, root_markers)
      if root ~= nil and root ~= "" then
        on_dir(root)
      end
    end,
  },
}

return M
