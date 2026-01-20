local Terminal = require("toggleterm.terminal").Terminal

local lazygit = Terminal:new {
  cmd = "lazygit",
  direction = "float",
  float_opts = {
    border = "single",
  },
  -- function to run on opening the terminal
  on_open = function(term)
    vim.cmd "startinsert!"
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = term.bufnr, noremap = true, silent = true })
    vim.keymap.set({ "n", "t" }, "<C-q>", function() term:toggle() end, { buffer = term.bufnr, noremap = true, silent = true })
  end,
  -- function to run on closing the terminal
  on_close = function()
    vim.cmd "startinsert!"
  end,
}

return lazygit
