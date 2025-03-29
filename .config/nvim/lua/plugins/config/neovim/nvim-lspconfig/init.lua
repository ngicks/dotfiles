local M = {}

M.opts = {
  capabilities = {
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = true,
      },
    },
  },
  inlay_hints = { enabled = true },
}

M.config = function(_, opts)
  require("nvchad.configs.lspconfig").defaults()

  local lspconfig = require "lspconfig"

  local nvlsp = require "nvchad.configs.lspconfig"

  local servers = {
    html = {},
    cssls = {},
    marksman = {}, -- markdown
    pyright = {}, -- python
    clangd = {},
    rust_analyzer = {},
  }

  local default_setups = vim.tbl_deep_extend("keep", opts, {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  })

  local providers =
    require("func.scan_conf_dir").load_local_dir("plugins/config/neovim/nvim-lspconfig/lsp_provider", true)

  for _, provider in ipairs(providers) do
    provider.config(servers, default_setups)
  end

  for name, lsp in pairs(servers) do
    lspconfig[name].setup(vim.tbl_deep_extend("keep", lsp, default_setups))
  end

  for _, provider in ipairs(providers) do
    if provider.post_setup then
      provider.post_setup()
    end
  end
end

return M
