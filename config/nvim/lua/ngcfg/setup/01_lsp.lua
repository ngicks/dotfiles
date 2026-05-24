require "lspconfig"

if vim.lsp.inlay_hint then
  vim.lsp.inlay_hint.enable(true)
end

local enabled = require("ngcfg.config.ls").lsp

vim.lsp.enable(enabled)
