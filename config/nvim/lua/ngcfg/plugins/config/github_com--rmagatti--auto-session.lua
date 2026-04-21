---@type NgPackPluginConfigModule
local M = {}

M.enable = function()
  return vim.env.IN_CONTAINER ~= "1"
end

M.opts = {
  suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
  -- log_level = 'debug',
}

return M
