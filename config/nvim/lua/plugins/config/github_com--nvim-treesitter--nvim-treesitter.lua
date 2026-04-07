local M = {}

local treesitter_path = vim.fs.joinpath(vim.fn.stdpath "data", "/treesitter")

M.build = ":TSUpdate"

M.opts = function()
  pcall(function()
    dofile(vim.g.base46_cache .. "syntax")
    dofile(vim.g.base46_cache .. "treesitter")
  end)

  return {
    install_dir = treesitter_path,
  }
end

M.config = function(_, opts)
  require("nvim-treesitter").setup(opts)

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("vim-treesitter-start", {}),
    callback = function()
      pcall(vim.treesitter.start)
    end,
  })
end

return M
