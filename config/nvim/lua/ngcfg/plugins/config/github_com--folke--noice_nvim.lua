---@type NgPackPluginConfigModule
local M = {}

M.init = function()
  vim.o.showmode = true
end

M.opts = {
  lsp = {
    hover = {
      enabled = false,
    },
    signature = {
      auto_open = {
        enabled = false,
      },
    },
    override = {},
  },
  presets = {
    bottom_search = true,
    command_palette = true,
    long_message_to_split = true,
  },
  routes = {
    {
      view = "mini",
      filter = { event = "msg_showmode" },
    },
  },
}

M.config = true

return M
