local funcs = require "ngcfg.plugins.funcs"
---@type NgPackSpecPlain[]
local plugins = require "ngcfg.plugins.list"

vim.api.nvim_create_user_command("CreatePluginConfigs", function()
  funcs.auto_create(plugins)
  print "Plugin config directories created/verified"
end, {})

vim.api.nvim_create_user_command("ListUnusedConf", function()
  print(vim.inspect(funcs.list_unused(plugins)))
end, {})

---@type NgPackSpecPlain[]
local merged = funcs.merge(plugins, require "ngcfg.plugins.default")

return merged
