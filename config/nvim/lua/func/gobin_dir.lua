local M = {}

M.gobin_dir = function()
  local gobin = vim.fn.system { "go", "env", "GOBIN" }
  gobin = gobin:match "^%s*(.-)%s*$"
  if gobin ~= nil and gobin ~= "" then
    return gobin
  end
  local gopath = vim.fn.system { "go", "env", "GOPATH" }
  return gopath:match "^%s*(.-)%s*$" .. "/bin"
end

return M
