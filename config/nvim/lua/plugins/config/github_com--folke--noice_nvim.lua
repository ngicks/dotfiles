---@type NgPluginConfigModule
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
}

M.config = true

return M
