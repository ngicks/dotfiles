-- Neovim's runtime knows neither extension, and the language servers attach by
-- filetype. vim-alloy ships its own ftdetect for ".als"; this entry keeps
-- detection independent of when that plugin gets loaded.
vim.filetype.add {
  extension = {
    als = "alloy",
    qnt = "quint",
  },
}
