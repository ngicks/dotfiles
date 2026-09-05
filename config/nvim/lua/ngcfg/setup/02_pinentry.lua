-- Dynamic PINENTRY_USER_DATA update for GPG pinentry popup support
-- Keeps the env var current so pinentry appears in the correct terminal
-- context when attaching to an existing tmux/zellij session from another
-- device. Refreshed on editor events and, since those alone proved too
-- sparse in practice, on a periodic timer as well.

-- Refresh interval in milliseconds (override via $HOMEENV_PINENTRY_REFRESH_MS).
local refresh_ms = tonumber(vim.env.HOMEENV_PINENTRY_REFRESH_MS) or 30000

local function enabled()
  return vim.env.HOMEENV_PREFER_TMUX_PINENTRY == "1"
end

local function trim(s)
  return (s or ""):gsub("%s+$", "")
end

local in_flight = false

-- Async: never block the UI, even from a timer.
local function update_tmux()
  if in_flight then
    return
  end
  in_flight = true

  local tmux_path = vim.fn.exepath "tmux"
  if tmux_path == "" then
    tmux_path = "tmux"
  end
  local tmux = vim.env.TMUX or ""

  -- client_tty never contains spaces; session names may, so it goes last.
  vim.system({ tmux_path, "display", "-p", "#{client_tty} #S" }, { text = true }, function(res)
    in_flight = false
    if res.code ~= 0 then
      return
    end
    local client_tty, session = trim(res.stdout):match "^(%S*) (.*)$"
    -- No attached client (detached session): keep the last known good value.
    if not session or session == "" or client_tty == "" then
      return
    end
    vim.schedule(function()
      vim.env.PINENTRY_USER_DATA = string.format("TMUX_POPUP:%s:%s:%s:%s", tmux_path, session, client_tty, tmux)
    end)
  end)
end

local function update_zellij()
  local zellij_path = vim.fn.exepath "zellij"
  if zellij_path == "" then
    zellij_path = "zellij"
  end
  local session = vim.env.ZELLIJ_SESSION_NAME or ""
  vim.env.PINENTRY_USER_DATA = string.format("ZELLIJ_POPUP:%s:%s", zellij_path, session)
end

local function update()
  if not enabled() then
    return
  end
  if vim.env.TMUX and vim.env.TMUX ~= "" then
    update_tmux()
  elseif vim.env.ZELLIJ and vim.env.ZELLIJ ~= "" then
    update_zellij()
  end
end

if enabled() then
  vim.api.nvim_create_autocmd({ "VimEnter", "VimResume", "FocusGained", "BufWritePost", "TermLeave" }, {
    callback = update,
    desc = "Update PINENTRY_USER_DATA on focus gain, resume, file save, or terminal leave",
  })

  local timer, err = vim.uv.new_timer()
  if not timer then
    vim.notify("pinentry: failed to create refresh timer: " .. tostring(err), vim.log.levels.WARN)
    return
  end
  timer:start(refresh_ms, refresh_ms, vim.schedule_wrap(update))
  vim.api.nvim_create_autocmd("VimLeavePre", {
    once = true,
    callback = function()
      if not timer:is_closing() then
        timer:stop()
        timer:close()
      end
    end,
  })
end
