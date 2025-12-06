local M = {}

M.opts = function()
  dofile(vim.g.base46_cache .. "mason")

  return {
    PATH = "skip",

    ui = {
      icons = {
        package_pending = " ",
        package_installed = " ",
        package_uninstalled = " ",
      },
    },

    max_concurrent_installers = 10,
  }
end

return M
