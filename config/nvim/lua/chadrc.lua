-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "chadracula",
  theme_toggle = { "chadracula", "rosepine-dawn" },
  transparency = true,
  hl_override = {
    DiffAdd = {
      fg = "NONE",
      bg = { "green", "black", 70 },
    },
    DiffDelete = {
      fg = "NONE",
      bg = { "red", "black", 70 },
    },
    DiffChange = {
      fg = "NONE",
      bg = { "light_grey", "black", 85 },
    },
    DiffText = {
      fg = "NONE",
      bg = { "red", "black", 55 },
    },
  },
  hl_add = {
    DiffTextAdd = {
      fg = "NONE",
      bg = { "green", "black", 55 },
    },
  },
}

M.term = {
  float = {
    row = 0.05,
    col = 0.05,
    width = 0.9,
    height = 0.8,
  },
}

M.lsp = {
  signature = false,
}

return M
