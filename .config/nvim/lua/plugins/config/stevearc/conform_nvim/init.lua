local M = {}

M.opts = {
  formatters_by_ft = {
    lua = { "stylua" },
    css = { "prettier" },
    html = { "prettier" },
    markdown = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    xml = { "xmlformatter" },
  },
  default_format_opts = {
    lsp_format = "fallback",
  },
  format_on_save = {
    -- These options will be passed to conform.format()
    timeout_ms = 500,
  },
}
return M
