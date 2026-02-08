local moon_home = vim.env.MOON_HOME or (vim.env.HOME .. "/.local/share/moonbit")

return {
  cmd = { moon_home .. "/bin/moonbit-lsp" },
  filetypes = { "moonbit" },
  root_markers = { "moon.mod.json" },
}
