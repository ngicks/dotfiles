---@class NgcfgAutoreloadConfig
---@field interval_ms integer

---@class NgcfgAutoreloadConfigPartial
---@field interval_ms? integer

---@class NgcfgAutoreloadState
---@field augroup? integer
---@field checking boolean
---@field config? NgcfgAutoreloadConfig
---@field timer? uv.uv_timer_t

---@class NgcfgAutoreloadModule
local M = {}

---@type NgcfgAutoreloadConfig
local defaults = {
  interval_ms = 2000,
}

---@type NgcfgAutoreloadState
local state = {
  augroup = nil,
  checking = false,
  config = nil,
  timer = nil,
}

local function is_file_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
    return false
  end

  if vim.api.nvim_get_option_value("buftype", { buf = bufnr }) ~= "" then
    return false
  end

  if vim.api.nvim_buf_get_name(bufnr) == "" then
    return false
  end

  if vim.api.nvim_get_option_value("autoread", { buf = bufnr }) == false then
    return false
  end

  if vim.api.nvim_get_option_value("modified", { buf = bufnr }) then
    return false
  end

  return true
end

local function should_skip_check()
  if vim.fn.getcmdwintype() ~= "" then
    return true
  end

  local mode = vim.api.nvim_get_mode().mode
  local prefix = mode:sub(1, 1)
  return prefix == "c" or prefix == "i" or prefix == "r" or prefix == "R" or prefix == "s" or prefix == "t"
end

function M.check_now()
  if state.checking or should_skip_check() then
    return
  end

  state.checking = true

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if is_file_buffer(bufnr) then
      pcall(function(...)
        return vim.cmd(...)
      end, ("checktime %d"):format(bufnr))
    end
  end

  state.checking = false
end

function M.stop()
  if state.timer then
    state.timer:stop()
    state.timer:close()
    state.timer = nil
  end
end

function M.start()
  if state.timer then
    return
  end

  state.timer = vim.uv.new_timer()
  -- uv callbacks cannot call most vim.api functions directly, so hop back to
  -- the main loop before running :checktime.
  state.timer:start(state.config.interval_ms, state.config.interval_ms, vim.schedule_wrap(M.check_now))
end

---@param opts? NgcfgAutoreloadConfigPartial
function M.setup(opts)
  state.config = vim.tbl_extend("force", defaults, opts or {})
  vim.o.autoread = true

  M.stop()

  state.augroup = vim.api.nvim_create_augroup("NgcfgAutoreload", { clear = true })

  vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
    group = state.augroup,
    callback = function()
      M.check_now()
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = state.augroup,
    callback = function()
      M.stop()
    end,
  })

  M.start()
end

---@type NgcfgAutoreloadModule
return M
