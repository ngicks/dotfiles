local M = {}

M.opts = function()
  return {
    ensure_installed = require("config.ls").lsp,
  }
end

return M
