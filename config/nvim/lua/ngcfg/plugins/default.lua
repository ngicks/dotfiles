---@class NgPackSpecPlainDefault
---@field version? vim.VersionRange|string
---@field branch? string
---@field commit? string

---@type NgPackSpecPlainDefault
return {
  version = vim.version.range "*",
}
