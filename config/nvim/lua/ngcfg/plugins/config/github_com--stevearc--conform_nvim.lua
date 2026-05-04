---@type NgPackPluginConfigModule
local M = {}

local golangci_lint_ls = require "ngcfg.config.ls.golangci_lint_ls"

local function go_formatters(bufnr)
  local fname = vim.api.nvim_buf_get_name(bufnr)
  local ver = golangci_lint_ls.detect_config_version(fname)
  if ver and ver >= 1 then
    return { "golangci_lint_v2" }
  end
  return { "goimports" }
end

M.opts = {
  formatters_by_ft = {
    go = go_formatters,
    lua = { "stylua" },
    css = { "prettier" },
    html = { "prettier" },
    markdown = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    xml = { "xmlformatter" },
    kdl = { "kdlfmt_format" },
    python = { "ruff_format" },
  },
  default_format_opts = {
    lsp_format = "fallback",
  },
  formatters = {
    golangci_lint_v2 = {
      command = golangci_lint_ls.format_commads[2][1],
      args = { unpack(golangci_lint_ls.format_commads[2], 2, #golangci_lint_ls.format_commads[2]) },
      cwd = function(ctx)
        return golangci_lint_ls.find_root(ctx.filename)
      end,
      stdin = true,
    },
  },
  format_on_save = {
    lsp_format = "fallback",
    timeout_ms = 1000,
  },
}
return M
