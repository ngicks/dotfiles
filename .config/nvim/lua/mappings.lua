require "nvchad.mappings"
local map = vim.keymap.set
local unmap = vim.keymap.del

-- jj or jk is too agressive to me.
map({ "i", "v" }, "<C-j>", "<ESC>", { desc = "back to normal mode." })
map("n", "<C-W>t", "<cmd>tabnew<cr>", { desc = "new tab." })

if vim.lsp.inlay_hint then
  map("n", "<leader>uh", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
  end, { desc = "Toggle Inlay Hints" })
end

-- remove M-i for floating windows as ESC works as Alt.
-- It is the terminal's behavior AFAIK.
unmap({ "n", "t" }, "<M-i>")
map({ "n", "t" }, "<M-f>", function()
  require("nvchad.term").toggle { pos = "float", id = "floatTerm" }
end, { desc = "terminal toggle floating term" })

-- remove nvchad's nvtree config and tie them nearly
unmap("n", "<C-n>")
unmap("n", "<leader>e")
map("n", "<leader>et", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })
map("n", "<leader>ef", "<cmd>NvimTreeFocus<CR>", { desc = "nvimtree focus window" })

-- theme selector is unnecessary for now.
unmap("n", "<leader>th")

-- use telescope live_grep_args in place of live_grep
unmap("n", "<leader>fw")
map("n", "<leader>fw", function()
  require("telescope").extensions.live_grep_args.live_grep_args()
end, { desc = "telescope live grep args" })

-- trouble
-- remove builtin LSP diagnose location list
unmap("n", "<leader>ds")
map("n", "<leader>tt", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
map("n", "<leader>tT", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer Diagnostics (Trouble)" })
map("n", "<leader>ts", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Symbols (Trouble)" })
map(
  "n",
  "<leader>tl",
  "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
  { desc = "LSP Definitions / references / ... (Trouble)" }
)
map("n", "<leader>tL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
map("n", "<leader>tQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })

-- dropbar
map("n", "<Leader>;", function()
  require("dropbar.api").pick()
end, { desc = "Pick symbols in winbar" })
map("n", "[;", function()
  require("dropbar.api").goto_context_start()
end, { desc = "Go to start of current context" })
map("n", "];", function()
  require("dropbar.api").select_next_context()
end, { desc = "Select next context" })

-- markdown renderer
map("n", "<leader>rm", function()
  require("render-markdown").toggle()
end, { desc = "Toggle Markdown Rendering" })

-- csv renderer
map("n", "<leader>rc", "<cmd>CsvViewToggle<cr>", { desc = "Toggle csv rendering" })

-- memo
map("n", "<leader>mn", ":MemoNew<CR>", { desc = "create a new memo" })
map("n", "<leader>ml", ":Telescope memo list<CR>", { desc = "telescope memo list" })
map("n", "<leader>mg", ":Telescope memo live_grep<CR>", { desc = "telescope memo live grep" })

-- lazygit
map("n", "<leader>gg", function()
  require("toggleterm_cmd.lazygit_floating"):toggle()
end, { noremap = true, silent = true, desc = "Toggle lazygit floating window" })

-- luadev
map("n", "<leader>ld", function()
  require("luadev").start()
end, { desc = ":Luadev" })

map("n", "<leader>ll", function()
  require("luadev").exec(vim.api.nvim_get_current_line())
end, { desc = "run current line of lua script" })

local buffer_to_string = function()
  local content = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)
  return table.concat(content, "\n")
end

map("n", "<leader>lf", function()
  require("luadev").exec(buffer_to_string())
end, { desc = "eval whole current buffer as lua script" })

-- claude code

vim.keymap.set("n", "<leader>ac", "<cmd>ClaudeCode<CR>", { desc = "Toggle Claude Code" })

-- DAP (Debug Adapter Protocol) keybindings
map("n", "<F5>", function()
  require("dap").continue()
end, { desc = "DAP Continue" })
map("n", "<F10>", function()
  require("dap").step_over()
end, { desc = "DAP Step Over" })
map("n", "<F12>", function()
  require("dap").step_into()
end, { desc = "DAP Step Into" })
map("n", "<F24>", function()
  require("dap").step_out()
end, { desc = "DAP Step Out" })
map("n", "<F9>", function()
  require("dap").toggle_breakpoint()
end, { desc = "DAP Toggle Breakpoint" })
map("n", "<leader>dB", function()
  require("dap").set_breakpoint(vim.fn.input "Breakpoint condition: ")
end, { desc = "DAP Set Conditional Breakpoint" })
map("n", "<leader>dp", function()
  require("dap").set_breakpoint(nil, nil, vim.fn.input "Log point message: ")
end, { desc = "DAP Set Log Point" })
map("n", "<leader>dr", function()
  require("dap").repl.open()
end, { desc = "DAP Open REPL" })
map("n", "<leader>dl", function()
  require("dap").run_last()
end, { desc = "DAP Run Last" })
map("n", "<leader>dt", function()
  require("dap").terminate()
end, { desc = "DAP Terminate" })

-- DAP UI keybindings
map("n", "<leader>du", function()
  require("dapui").toggle()
end, { desc = "DAP UI Toggle" })
map("n", "<leader>de", function()
  require("dapui").eval()
end, { desc = "DAP UI Eval" })
map("v", "<leader>de", function()
  require("dapui").eval()
end, { desc = "DAP UI Eval Selection" })

-- DAP Virtual Text keybindings
map("n", "<leader>dv", "<cmd>DapVirtualTextToggle<cr>", { desc = "DAP Virtual Text Toggle" })
