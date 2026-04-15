local terminal = require "snacks.terminal"

local M = {}

---@param slot string
---@param win table
local function toggle_terminal(slot, win)
  terminal(nil, {
    env = {
      NG_TERM_SLOT = slot,
    },
    win = win,
  })
end

function M.horizontal()
  toggle_terminal("horizontal", {
    position = "bottom",
    height = 0.3,
  })
end

function M.vertical()
  toggle_terminal("vertical", {
    position = "right",
    width = 0.3,
  })
end

function M.floating()
  toggle_terminal("floating", {
    border = "single",
    position = "float",
  })
end

function M.lazygit()
  require "snacks.lazygit" {
    win = {
      border = "single",
      on_buf = function(self)
        vim.keymap.set({ "n", "t" }, "<C-q>", function()
          self:hide()
        end, { buffer = self.buf, silent = true })
      end,
    },
  }
end

return M
