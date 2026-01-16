local M = {}

M.opts = function()
  return {
    size = function(term)
      if term.direction == "horizontal" then
        return 20
      elseif term.direction == "vertical" then
        return vim.o.columns * 0.3
      end
    end,
  }
end

return M
