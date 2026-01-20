local M = {}

M.auto_create = function(plugins)
  for _, plugin in ipairs(plugins) do
    local path = plugin[1]:gsub("%.", "_")
    local dir = vim.fn.stdpath "config" .. "/lua/plugins/config/" .. path

    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
    if vim.fn.filereadable(dir .. "/init.lua") == 0 then
      vim.fn.writefile({ "local M = {}", "", "return M" }, dir .. "/init.lua")
    end
  end
end

M.merge = function(plugins)
  for _, plugin in ipairs(plugins) do
    local path = plugin[1]:gsub("%.", "_")
    local conf = require("plugins.config." .. path:gsub("/", "."))
    for _, f in ipairs { "init", "opts", "config", "main", "build" } do
      if conf[f] then
        plugin[f] = conf[f]
      end
    end
  end
  return plugins
end

M.list_unused = function(plugins)
  local config_dir = vim.fn.stdpath "config" .. "/lua/plugins/config"

  -- Build set of expected config paths from plugins
  local expected = {}
  for _, plugin in ipairs(plugins) do
    local path = plugin[1]:gsub("%.", "_")
    expected[path] = true
  end

  -- Find all existing config directories
  local unused = {}
  local handle = vim.uv.fs_scandir(config_dir)
  if not handle then
    return unused
  end

  while true do
    local name, type = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if type == "directory" then
      -- Recursively scan for nested directories (e.g., folke/which_key_nvim)
      local subhandle = vim.uv.fs_scandir(config_dir .. "/" .. name)
      if subhandle then
        while true do
          local subname, subtype = vim.uv.fs_scandir_next(subhandle)
          if not subname then
            break
          end
          if subtype == "directory" then
            local full_path = name .. "/" .. subname
            if not expected[full_path] then
              table.insert(unused, full_path)
            end
          end
        end
      end
    end
  end

  return unused
end

return M
