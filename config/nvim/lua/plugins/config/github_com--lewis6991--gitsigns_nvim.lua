local M = {}

M.opts = function()
  dofile(vim.g.base46_cache .. "git")

  return {
    signs = {
      delete = { text = "󰍵" },
      changedelete = { text = "󱕖" },
    },
  }
end

return M
