---@type NgPackPluginConfigModule
local M = {}

M.opts = {
  enhanced_diff_hl = true,
  use_icons = true,
  view = {
    default = { layout = "diff2_horizontal" },
    merge_tool = { layout = "diff3_horizontal" },
  },
  file_panel = {
    listing_style = "tree",
    win_config = { position = "left", width = 35 }, -- Use "auto" to fit content
  },
  hooks = {}, -- See :h diffview-config-hooks
  keymaps = {}, -- See :h diffview-config-keymaps
}

return M
