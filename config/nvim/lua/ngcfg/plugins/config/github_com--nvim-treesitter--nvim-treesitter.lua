---@type NgPackPluginConfigModule
local M = {}

local treesitter_path = vim.fs.joinpath(vim.fn.stdpath "data", "/treesitter")

M.pack_changed = function()
  -- On a fresh (headless) install this event fires before the plugin is on the
  -- runtimepath, so :TSUpdate is not registered yet; defer until it is and
  -- skip quietly when the session ends before the plugin ever loads.
  vim.schedule(function()
    if vim.fn.exists ":TSUpdate" == 2 then
      vim.cmd "TSUpdate"
    end
  end)
end

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
