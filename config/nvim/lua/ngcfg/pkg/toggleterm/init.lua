local M = {}

---@type NgcfgToggleTermTerminals
local terminals = require "ngcfg.pkg.toggleterm.terminals"

---@param term Terminal
local function ensure_shell_started(term)
  if term.job_id and vim.fn.jobwait({ term.job_id }, 0)[1] == -1 then
    return
  end

  term:spawn()
end

---@return nil
function M.setup()
  ensure_shell_started(terminals.horizontal.t)
  ensure_shell_started(terminals.vertical.t)
  ensure_shell_started(terminals.floating.t)
end

---@return NgcfgToggleTermTerminals
function M.terminals()
  return terminals
end

---@return Terminal
function M.lazygit()
  return require "ngcfg.pkg.toggleterm.lazygit_floating"
end

return M
