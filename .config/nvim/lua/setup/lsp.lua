if vim.lsp.inlay_hint then
  vim.lsp.inlay_hint.enable(true)
end

vim.lsp.enable(require "config.ls")
