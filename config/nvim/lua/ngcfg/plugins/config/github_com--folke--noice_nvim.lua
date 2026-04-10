---@type NgPackPluginConfigModule
local M = {}

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
}

M.config = true

return M
