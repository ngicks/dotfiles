local M = {}

M.opts = function()
  return {
    ensure_installed = require("config.ls").tools,
  }
end

M.config = function(_, opts)
  require("mason-tool-installer").setup(opts)
end

return M
