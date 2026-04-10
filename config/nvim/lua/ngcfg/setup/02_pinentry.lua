-- Dynamic PINENTRY_USER_DATA update for GPG pinentry popup support
-- Updates env var on FocusGained/BufWritePost to ensure pinentry appears
-- in the correct terminal context when SSH-ing into existing tmux sessions

local function update_pinentry_user_data()
  -- Check if feature is enabled
  if vim.env.HOMEENV_PREFER_TMUX_PINENTRY ~= "1" then
    return
  end

  -- Handle tmux
  if vim.env.TMUX and vim.env.TMUX ~= "" then
    local tmux_path = vim.fn.exepath "tmux"
    if tmux_path == "" then
      tmux_path = "tmux"
    end

    local session = vim.fn.system({ "tmux", "display", "-p", "#S" }):gsub("%s+$", "")
    local client_tty = vim.fn.system({ "tmux", "display", "-p", "#{client_tty}" }):gsub("%s+$", "")
    local tmux = vim.env.TMUX or ""

    vim.env.PINENTRY_USER_DATA = string.format("TMUX_POPUP:%s:%s:%s:%s", tmux_path, session, client_tty, tmux)
    return
  end

  -- Handle zellij
  if vim.env.ZELLIJ and vim.env.ZELLIJ ~= "" then
    local zellij_path = vim.fn.exepath "zellij"
    if zellij_path == "" then
      zellij_path = "zellij"
    end

    local session = vim.env.ZELLIJ_SESSION_NAME or ""
    vim.env.PINENTRY_USER_DATA = string.format("ZELLIJ_POPUP:%s:%s", zellij_path, session)
  end
end

vim.api.nvim_create_autocmd({ "FocusGained", "BufWritePost" }, {
  callback = update_pinentry_user_data,
  desc = "Update PINENTRY_USER_DATA on focus gain or file save",
})
