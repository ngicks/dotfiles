local M = {}

M.opts = {
  ensure_installed = require("config.ls").tools,
}

M.config = function(_, opts)
  require("mason-tool-installer").setup(opts)
end

return M
