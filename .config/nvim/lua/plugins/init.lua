local funcs = require "plugins._funcs.funcs"
local plugins = require "plugins.list"

funcs.auto_create(plugins)

vim.api.nvim_create_user_command("ListUnusedConf", function(opts)
  print(vim.inspect(funcs.list_unused(plugins)))
end, {})

return funcs.merge(plugins)
