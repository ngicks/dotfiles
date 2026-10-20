---@type NgPackPluginConfigModule
local M = {}

M.config = function()
  require("scrollbar").setup({
    providers = { gitsigns = true },
  })
end

return M
