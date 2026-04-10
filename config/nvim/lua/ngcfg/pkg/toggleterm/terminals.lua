local Terminal = require("toggleterm.terminal").Terminal

---@class NgToggleTerms
---@field horizontal NgToggleTerm
---@field vertical NgToggleTerm
---@field floating NgToggleTerm

-- A wrapper for |Terminal|
---@class NgToggleTerm
---@field t Terminal
---@field size? fun(term: Terminal): number?
---@field toggle fun(self: NgToggleTerm)
local NgToggleTerm = {}
NgToggleTerm.__index = NgToggleTerm

---@class NgToggleTermArgs
---@field t Terminal
---@field size? function(term: Terminal) -> integer

---@param tb NgToggleTermArgs
function NgToggleTerm:new(tb)
  return setmetatable(tb, NgToggleTerm)
end

function NgToggleTerm:toggle()
  if self.size ~= nil then
    self.t:toggle(self.size(self.t))
  else
    self.t:toggle()
  end
end

local M = {}

local h = NgToggleTerm:new {
  size = function()
    return 20
  end,
  t = Terminal:new {
    direction = "horizontal",
    on_open = function()
      vim.cmd "startinsert!"
    end,
  },
}

M.horizontal = h

local v = NgToggleTerm:new {
  size = function()
    return vim.o.columns * 0.3
  end,
  t = Terminal:new {
    direction = "vertical",
    on_open = function()
      vim.cmd "startinsert!"
    end,
  },
}

M.vertical = v

local f = NgToggleTerm:new {
  t = Terminal:new {
    direction = "float",
    float_opts = {
      border = "single",
    },
    on_open = function()
      vim.cmd "startinsert!"
    end,
  },
}

M.floating = f

return M
