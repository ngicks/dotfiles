---@type NgPackPluginConfigModule
local M = {}

M.opts = {
  history = true,
  updateevents = "TextChanged,TextChangedI",
}

M.config = function(_, opts)
  require("luasnip").config.set_config(opts)
  require "config.luasnip"
end

return M
