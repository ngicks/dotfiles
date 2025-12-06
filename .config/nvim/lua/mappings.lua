local map = vim.keymap.set

map("i", "<C-b>", "<ESC>^i", { desc = "move beginning of line" })
map("i", "<C-e>", "<End>", { desc = "move end of line" })
map("i", "<C-h>", "<Left>", { desc = "move left" })
map("i", "<C-l>", "<Right>", { desc = "move right" })
map("i", "<C-j>", "<Down>", { desc = "move down" })
map("i", "<C-k>", "<Up>", { desc = "move up" })

map("n", "<C-h>", "<C-w>h", { desc = "switch window left" })
map("n", "<C-l>", "<C-w>l", { desc = "switch window right" })
map("n", "<C-j>", "<C-w>j", { desc = "switch window down" })
map("n", "<C-k>", "<C-w>k", { desc = "switch window up" })

map("n", "<Esc>", "<cmd>noh<CR>", { desc = "general clear highlights" })

map("n", "<C-s>", "<cmd>w<CR>", { desc = "general save file" })
map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "general copy whole file" })

map("n", "<leader>n", "<cmd>set nu!<CR>", { desc = "toggle line number" })
map("n", "<leader>rn", "<cmd>set rnu!<CR>", { desc = "toggle relative number" })
map("n", "<leader>ch", "<cmd>NvCheatsheet<CR>", { desc = "toggle nvcheatsheet" })

map({ "n", "x" }, "<leader>fm", function()
  require("conform").format { lsp_fallback = true }
end, { desc = "general format file" })

-- global lsp mappings
-- map("n", "<leader>ds", vim.diagnostic.setloclist, { desc = "LSP diagnostic loclist" })

-- tabufline
if require("nvconfig").ui.tabufline.enabled then
  map("n", "<leader>b", "<cmd>enew<CR>", { desc = "buffer new" })

  map("n", "<tab>", function()
    require("nvchad.tabufline").next()
  end, { desc = "buffer goto next" })

  map("n", "<S-tab>", function()
    require("nvchad.tabufline").prev()
  end, { desc = "buffer goto prev" })

  map("n", "<leader>x", function()
    require("nvchad.tabufline").close_buffer()
  end, { desc = "buffer close" })
end

-- Comment
map("n", "<leader>/", "gcc", { desc = "toggle comment", remap = true })
map("v", "<leader>/", "gc", { desc = "toggle comment", remap = true })

-- nvimtree
-- map("n", "<C-n>", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })
-- map("n", "<leader>e", "<cmd>NvimTreeFocus<CR>", { desc = "nvimtree focus window" })

-- telescope
-- map("n", "<leader>fw", "<cmd>Telescope live_grep<CR>", { desc = "telescope live grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "telescope find buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "telescope help page" })
map("n", "<leader>ma", "<cmd>Telescope marks<CR>", { desc = "telescope find marks" })
map("n", "<leader>fo", "<cmd>Telescope oldfiles<CR>", { desc = "telescope find oldfiles" })
map("n", "<leader>fz", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "telescope find in current buffer" })
map("n", "<leader>cm", "<cmd>Telescope git_commits<CR>", { desc = "telescope git commits" })
map("n", "<leader>gt", "<cmd>Telescope git_status<CR>", { desc = "telescope git status" })
map("n", "<leader>pt", "<cmd>Telescope terms<CR>", { desc = "telescope pick hidden term" })

-- map("n", "<leader>th", function()
--   require("nvchad.themes").open()
-- end, { desc = "telescope nvchad themes" })

map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "telescope find files" })
map(
  "n",
  "<leader>fa",
  "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
  { desc = "telescope find all files" }
)

-- terminal
map("t", "<C-x>", "<C-\\><C-N>", { desc = "terminal escape terminal mode" })

-- new terminals
map("n", "<leader>h", function()
  require("nvchad.term").new { pos = "sp" }
end, { desc = "terminal new horizontal term" })

map("n", "<leader>v", function()
  require("nvchad.term").new { pos = "vsp" }
end, { desc = "terminal new vertical term" })

-- toggleable
map({ "n", "t" }, "<A-v>", function()
  require("nvchad.term").toggle { pos = "vsp", id = "vtoggleTerm" }
end, { desc = "terminal toggleable vertical term" })

map({ "n", "t" }, "<A-h>", function()
  require("nvchad.term").toggle { pos = "sp", id = "htoggleTerm" }
end, { desc = "terminal toggleable horizontal term" })

-- whichkey
map("n", "<leader>wK", "<cmd>WhichKey <CR>", { desc = "whichkey all keymaps" })

map("n", "<leader>wk", function()
  vim.cmd("WhichKey " .. vim.fn.input "WhichKey: ")
end, { desc = "whichkey query lookup" })

-- jj or jk is too agressive to me.
map({ "i", "v" }, "<C-j>", "<ESC>", { desc = "back to normal mode." })
map("n", "<C-W>t", "<cmd>tabnew<cr>", { desc = "new tab." })

if vim.lsp.inlay_hint then
  map("n", "<leader>uh", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
  end, { desc = "Toggle Inlay Hints" })
end

map({ "n", "t" }, "<M-f>", function()
  require("nvchad.term").toggle { pos = "float", id = "floatTerm" }
end, { desc = "terminal toggle floating term" })

-- remove nvchad's nvtree config and tie them nearly
map("n", "<leader>et", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })
map("n", "<leader>ef", "<cmd>NvimTreeFocus<CR>", { desc = "nvimtree focus window" })

-- use telescope live_grep_args in place of live_grep
map("n", "<leader>fw", function()
  require("telescope").extensions.live_grep_args.live_grep_args()
end, { desc = "telescope live grep args" })

-- trouble
-- remove builtin LSP diagnose location list
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
