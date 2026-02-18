local M = {}

M.opts = function()
  return {
    ensure_installed = require("config.ls").tools,
    handlers = {
      function(config)
        require("mason-nvim-dap").default_setup(config)
      end,
    },
  }
end

return M
