local Terminal = require("toggleterm.terminal").Terminal
local is_exiting = false

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("NgToggleTermLifecycle", { clear = true }),
  callback = function()
    is_exiting = true
  end,
})

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

---@param term Terminal
local function spawn(term)
  if term.job_id and vim.fn.jobwait({ term.job_id }, 0)[1] == -1 then
    return
  end
  vim.schedule(function()
    if is_exiting then
      return
    end
    term:spawn()
  end)
end

---@param tb NgToggleTermArgs
function NgToggleTerm:new(tb)
  tb.t.on_open = function()
    vim.cmd "startinsert!"
  end
  tb.t.on_exit = function(t)
    if is_exiting then
      return
    end
    vim.schedule(function()
      if is_exiting then
        return
      end
      spawn(t)
    end)
  end
  return setmetatable(tb, NgToggleTerm)
end

function NgToggleTerm:prepare()
  if is_exiting then
    return
  end
  spawn(self.t)
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
  },
}

M.horizontal = h

local v = NgToggleTerm:new {
  size = function()
    return vim.o.columns * 0.3
  end,
  t = Terminal:new {
    direction = "vertical",
  },
}

M.vertical = v

local f = NgToggleTerm:new {
  t = Terminal:new {
    direction = "float",
    float_opts = {
      border = "single",
    },
  },
}

M.floating = f

return M
