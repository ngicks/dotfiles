local plugins = require "plugins.list"

for _, plugin in ipairs(plugins) do
  local path = plugin[1]:gsub("%.", "_")
  local dir = vim.fn.stdpath "config" .. "/lua/plugins/config/" .. path

  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
  if vim.fn.filereadable(dir .. "/init.lua") == 0 then
    vim.fn.writefile({ "local M = {}", "", "return M" }, dir .. "/init.lua")
  end

  local conf = require("plugins.config." .. path:gsub("/", "."))
  for _, f in ipairs { "init", "opts", "config", "main", "build" } do
    if conf[f] then
      plugin[f] = conf[f]
    end
  end
end

return plugins
