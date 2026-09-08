-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "chadracula",
  theme_toggle = { "chadracula", "rosepine-dawn" },
  transparency = true,
  -- Diff backgrounds keep fg unset so tree-sitter/LSP colors show through.
  -- They blend toward darker_black instead of black: a tint adds lightness,
  -- so starting below the Normal bg keeps the result near Normal's lightness
  -- and dim groups such as @comment stay readable. Whole-line groups get a
  -- faint tint; DiffText/DiffTextAdd mark short changed spans and can be bolder.
  hl_override = {
    DiffAdd = {
      fg = "NONE",
      bg = { "green", "darker_black", 88 },
    },
    DiffDelete = {
      fg = "NONE",
      bg = { "red", "darker_black", 88 },
    },
    DiffChange = {
      fg = "NONE",
      bg = { "light_grey", "darker_black", 90 },
    },
    DiffText = {
      fg = "NONE",
      bg = { "red", "darker_black", 75 },
    },
  },
  hl_add = {
    DiffTextAdd = {
      fg = "NONE",
      bg = { "green", "darker_black", 75 },
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
