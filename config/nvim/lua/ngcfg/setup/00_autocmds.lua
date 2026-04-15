local autocmd = vim.api.nvim_create_autocmd

local function fit_quickfix_windows()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == "quickfix" then
      local info = vim.fn.getwininfo(win)[1]
      local size

      if info.loclist == 1 then
        size = vim.fn.getloclist(info.winnr, { size = 0 }).size
      else
        size = vim.fn.getqflist({ size = 0 }).size
      end

      local target = math.max(size, 1)
      local current = vim.api.nvim_win_get_height(win)

      if current > target then
        pcall(vim.api.nvim_win_set_height, win, target)
      end
    end
  end
end

-- user event that loads after UIEnter + only if file buf is there
autocmd({ "UIEnter", "BufReadPost", "BufNewFile" }, {
  group = vim.api.nvim_create_augroup("NvFilePost", { clear = true }),
  callback = function(args)
    local file = vim.api.nvim_buf_get_name(args.buf)
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = args.buf })

    if not vim.g.ui_entered and args.event == "UIEnter" then
      vim.g.ui_entered = true
    end

    if file ~= "" and buftype ~= "nofile" and vim.g.ui_entered then
      vim.api.nvim_exec_autocmds("User", { pattern = "FilePost", modeline = false })
      vim.api.nvim_del_augroup_by_name "NvFilePost"

      vim.schedule(function()
        vim.api.nvim_exec_autocmds("FileType", {})

        if vim.g.editorconfig then
          require("editorconfig").config(args.buf)
        end
      end)
    end
  end,
})

autocmd({ "WinClosed", "VimResized" }, {
  group = vim.api.nvim_create_augroup("NgQuickfixAutoFit", { clear = true }),
  callback = function()
    vim.schedule(fit_quickfix_windows)
  end,
})
