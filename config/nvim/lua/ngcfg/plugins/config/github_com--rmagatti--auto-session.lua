---@type NgPackPluginConfigModule
local M = {}

M.enable = function()
  return vim.env.IN_CONTAINER ~= "1"
end

M.opts = {
  purge_after_minutes = 120,
  suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
  -- log_level = 'debug',
}

return M
