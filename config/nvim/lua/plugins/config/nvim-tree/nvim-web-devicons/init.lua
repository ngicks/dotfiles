local M = {}

M.opts = function()
  dofile(vim.g.base46_cache .. "devicons")
  return { override = require "nvchad.icons.devicons" }
end

return M
