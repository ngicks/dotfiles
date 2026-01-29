local funcs = require "plugins._funcs.funcs"
local plugins = require "plugins.list"

vim.schedule(function()
  funcs.auto_create(plugins)

  vim.api.nvim_create_user_command("ListUnusedConf", function()
    print(vim.inspect(funcs.list_unused(plugins)))
  end, {})
end)

return funcs.merge(plugins)
