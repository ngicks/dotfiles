local M = {}

M.opts = function()
  pcall(function()
    dofile(vim.g.base46_cache .. "syntax")
    dofile(vim.g.base46_cache .. "treesitter")
  end)

  return {
    ensure_installed = {
      "lua",
      "luadoc",
      "printf",
      "vim",
      "vimdoc",
      "vim",
      "lua",
      "vimdoc",
      "html",
      "css",
      "markdown",
      "go",
      "rust",
    },

    highlight = {
      enable = true,
      use_languagetree = true,
    },

    indent = { enable = true },
  }
end

M.config = function(_, opts)
  require("nvim-treesitter.configs").setup(opts)
end

return M
