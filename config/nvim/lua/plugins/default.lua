---@class NgPackSpecPlainDefault
---@field version? vim.VersionRange|string
---@field branch? string
---@field commit? string

---@type NgPackSpecPlainDefault
return {
  -- commented out until version comparison logic in vim.pack.add is fixed.
  -- It always be thought needing to upate lock file.
  -- version = vim.version.range "*",
}
