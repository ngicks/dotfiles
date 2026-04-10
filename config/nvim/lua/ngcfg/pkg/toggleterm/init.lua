local M = {}

---@type NgToggleTerms
local terminals = require "ngcfg.pkg.toggleterm.terminals"

---@return nil
function M.setup()
  terminals.horizontal:prepare()
  terminals.vertical:prepare()
  terminals.floating:prepare()
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
