local M = {}

M.opts = {
  indent = { char = "│", highlight = "IblChar" },
  scope = { char = "│", highlight = "IblScopeChar" },
}

M.config = function(_, opts)
  dofile(vim.g.base46_cache .. "blankline")

  local hooks = require "ibl.hooks"
  hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)
  require("ibl").setup(opts)

  dofile(vim.g.base46_cache .. "blankline")
end

return M
