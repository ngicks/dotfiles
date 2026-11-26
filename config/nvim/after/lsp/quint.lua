-- nvim-lspconfig ships no Quint config, so this file is the whole definition.
return {
  cmd = { "quint-language-server", "--stdio" },
  filetypes = { "quint" },
  root_markers = { ".git" },
}
