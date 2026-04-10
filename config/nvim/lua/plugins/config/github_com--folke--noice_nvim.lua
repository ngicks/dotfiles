---@type NgPackPluginConfigModule
local M = {}

M.opts = {
  lsp = {
    override = {},
  },
  presets = {
    bottom_search = true,
    command_palette = true,
    long_message_to_split = true,
  },
  views = {
    hover = {
      border = {
        style = "single",
      },
    },
  },
}

M.config = true

return M
