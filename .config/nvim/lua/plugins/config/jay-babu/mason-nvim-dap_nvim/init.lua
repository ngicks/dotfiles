local M = {}

M.opts = {
  ensure_installed = require("config.ls").tools,
  handlers = {
    function(config)
      require("mason-nvim-dap").default_setup(config)
    end,
  },
}
return M
