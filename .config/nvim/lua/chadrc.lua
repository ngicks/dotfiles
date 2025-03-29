-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "chadracula-evondev",
  theme_toggle = { "chadracula-evondev", "rosepine-dawn" },
}

M.term = {
  float = {
    row = 0.05,
    col = 0.05,
    width = 0.9,
    height = 0.8,
  },
}

return M
