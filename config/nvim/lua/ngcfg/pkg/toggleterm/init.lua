local M = {}

---@type NgToggleTerms
local terminals = require "ngcfg.pkg.toggleterm.terminals"

---@return nil
function M.setup()
  terminals.setup()
end

---@return NgToggleTerms
function M.terminals()
  return terminals
end

---@return Terminal
function M.lazygit()
  return require "ngcfg.pkg.toggleterm.lazygit_floating"
end

return M
