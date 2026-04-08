---@class NgPluginFuncs
local M = {}
---@type NgPluginSpecDefaults
local default_spec = require "plugins.default"

---@param plugin NgPluginSpec
---@return string
local function config_name(plugin)
  if type(plugin.src) ~= "string" or plugin.src == "" then
    error("plugin spec must contain full src URL: " .. vim.inspect(plugin))
  end

  if not plugin.src:find("://", 1, true) then
    error("plugin spec src must be full URL: " .. plugin.src)
  end

  return plugin.src:gsub("^[%w.+-]+://", ""):gsub("/", "--"):gsub("%.", "_")
end

---@param plugins NgPluginSpec[]
M.auto_create = function(plugins)
  for _, plugin in ipairs(plugins) do
    local path = config_name(plugin)
    local file = vim.fn.stdpath "config" .. "/lua/plugins/config/" .. path .. ".lua"

    if vim.fn.filereadable(file) == 0 then
      vim.fn.writefile({ "local M = {}", "", "return M" }, file)
    end
  end
end

---@param plugins NgPluginSpec[]
---@return NgPluginSpec[]
M.merge = function(plugins)
  ---@type NgPluginSpec[]
  local merged = {}

  for _, plugin in ipairs(plugins) do
    ---@type NgPluginSpec
    local spec = vim.tbl_extend("force", {}, default_spec, plugin)
    local path = config_name(plugin)

    ---@type boolean, NgPluginConfigModule
    local success, conf = pcall(require, "plugins.config." .. path)

    if not success then
      vim.notify("missing plugin config: " .. path, vim.log.levels.WARN)
    else
      for _, f in ipairs { "init", "opts", "config", "main", "build" } do
        if conf[f] ~= nil then
          spec[f] = conf[f]
        end
      end
    end

    table.insert(merged, spec)
  end

  return merged
end

---@param plugins NgPluginSpec[]
---@return string[]
M.list_unused = function(plugins)
  local config_dir = vim.fs.joinpath(vim.fn.stdpath "config", "lua", "plugins", "config")

  -- Build set of expected config paths from plugins.
  ---@type table<string, boolean>
  local expected = {}
  for _, plugin in ipairs(plugins) do
    local path = config_name(plugin)
    expected[path] = true
  end

  -- With a flat config layout every plugin config is a direct child Lua file in config_dir.
  ---@type string[]
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
    if type == "file" and name:sub(-4) == ".lua" then
      local mod = name:sub(1, -5)
      if not expected[mod] then
        table.insert(unused, mod)
      end
    end
  end

  return unused
end

return M
