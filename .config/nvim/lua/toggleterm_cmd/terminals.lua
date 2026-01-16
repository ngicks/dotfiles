local Terminal = require("toggleterm.terminal").Terminal

local M = {}

local function size(term)
  if term.direction == "horizontal" then
    return 20
  elseif term.direction == "vertical" then
    return vim.o.columns * 0.3
  end
end

local h = {
  size = size,
  t = Terminal:new {
    direction = "horizontal",
    on_open = function()
      vim.cmd "startinsert!"
    end,
  },
}

function h:toggle()
  self.t:toggle(self.size(self.t))
end

M.horizontal = h

local v = {
  size = size,
  t = Terminal:new {
    direction = "vertical",
    on_open = function()
      vim.cmd "startinsert!"
    end,
  },
}

function v:toggle()
  self.t:toggle(self.size(self.t))
end

M.vertical = v

local f = {
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

function f:toggle()
  self.t:toggle()
end

M.floating = f

return M
