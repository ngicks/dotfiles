---@type NgPackPluginConfigModule
local M = {}

M.opts = function()
  return {
    size = function(term)
      if term.direction == "horizontal" then
        return math.max(10, math.floor(vim.o.lines * 0.3))
      elseif term.direction == "vertical" then
        return vim.o.columns * 0.3
      end
    end,
  }
end

return M
