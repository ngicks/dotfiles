require "lspconfig"

if vim.lsp.inlay_hint then
  vim.lsp.inlay_hint.enable(true)
end

local enabled = require("config.ls").lsp

for _, lsName in ipairs(enabled) do
  local config = vim.lsp.config[lsName]
  if config and config.root_dir == nil then
    local markers = config.root_markers
    vim.lsp.config(lsName, {
      root_dir = function(bufnr, on_dir)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        local root = vim.fs.root(fname, markers or { ".git" })
        if root then
          on_dir(root)
        end
      end,
    })
  end
end

-- not really sure why tho,
-- Once ls is activated, it is kept enabled even when I remove lines which enable it.
-- I don't like it, but -- For a desparate maesure, I'm putting this empty root_dir func.
-- If a config does not have root_dir, then it will NEVER be enabled
-- (and seemingly most of configs in neovim/nvim-lspconfig does not have it.)
vim.lsp.config("*", {
  root_dir = function(bufnr)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    vim.notify("catch-all root_dir is called for " .. fname, vim.log.levels.WARN)
  end,
})

vim.lsp.enable(enabled)
