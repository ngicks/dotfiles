-- moonbit.nvim detects only ".mbt" and ".mbti"; MoonBit scripts use ".mbtx".
vim.filetype.add {
  extension = {
    mbtx = "moonbit",
  },
}
