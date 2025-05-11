local M = {}

M.opts = {
  ensure_installed = { "javadbg", "javatest" },
  handlers = {
    function(config)
      require("mason-nvim-dap").default_setup(config)
    end,
  },
}
return M
