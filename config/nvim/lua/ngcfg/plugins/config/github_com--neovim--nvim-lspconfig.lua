---@type NgPackPluginConfigModule
local M = {}

M.config = function()
  require("ngcfg.config.lsp-defaults").defaults()
end

return M
