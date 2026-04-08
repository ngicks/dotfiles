---@class NgPackModule
local M = {}
---@type NgPackUtil
local util = require "pack.util"

---@param plugins NgPluginSpec[]
---@return NgPluginSpec[]
local function normalize_plugins(plugins)
  ---@type NgPluginSpec[]
  local normalized = {}
  ---@type table<string, boolean>
  local seen = {}

  for _, spec in ipairs(plugins) do
    local name = util.plugin_name(spec)
    if seen[name] then
      error("duplicate plugin name in plugins.list: " .. name)
    end

    seen[name] = true
    spec.name = name
    spec.src = util.plugin_src(spec)
    spec.phase = util.phase(spec)
    spec._pack_spec = util.spec_to_pack(spec)
    table.insert(normalized, spec)
  end

  return normalized
end

---@param spec NgPluginSpec
---@return NgPluginOpts
local function resolve_opts(spec)
  if type(spec.opts) == "function" then
    return spec.opts(spec)
  end
  return spec.opts
end

---@param spec NgPluginSpec
---@return any|nil
local function require_main(spec)
  local main = util.infer_main(spec)
  local ok, mod = pcall(require, main)
  if not ok then
    vim.notify(("failed to require %s for %s: %s"):format(main, spec.name, mod), vim.log.levels.ERROR)
    return nil
  end
  return mod
end

-- return callable instance of given a
---@param a any
---@return function|table|nil
local function callable(a)
  local typ = type(a)
  if typ == "function" then
    return a
  end
  if typ == "table" then
    local mt = getmetatable(a)
    if mt and type(mt.__call) == "function" then
      return a
    end
  end
  return nil
end

---@param mod any
---@param spec NgPluginSpec
---@param opts NgPluginOpts
---@return boolean
local function call_setup(mod, spec, opts)
  local setup = callable(type(mod) == "table" and mod.setup or nil)
  if setup == nil then
    vim.notify(("missing callable setup() for %s"):format(spec.name), vim.log.levels.WARN)
    return false
  end
  setup(opts)
  return true
end

---@param spec NgPluginSpec
local function ensure_loaded(spec)
  if spec._loaded then
    return
  end

  vim.cmd("packadd " .. vim.fn.fnameescape(spec.name))
  spec._loaded = true
end

---@param spec NgPluginSpec
local function run_init(spec)
  if spec._initialized then
    return
  end

  if type(spec.init) == "function" then
    spec.init()
  end

  spec._initialized = true
end

---@param spec NgPluginSpec
local function run_config(spec)
  if spec._configured then
    return
  end

  ensure_loaded(spec)

  local opts = resolve_opts(spec)

  if type(spec.config) == "function" then
    spec.config(spec, opts or {})
  elseif spec.config == true then
    local mod = require_main(spec)
    if mod ~= nil then
      call_setup(mod, spec, opts or {})
    end
  elseif opts ~= nil and spec.config == nil then
    local mod = require_main(spec)
    if mod ~= nil then
      call_setup(mod, spec, type(opts) == "table" and opts or {})
    end
  end

  spec._configured = true
end

---@param spec NgPluginSpec
---@param ev NgPluginBuildEvent
local function run_build(spec, ev)
  if spec.build == nil then
    return
  end

  if ev.data.kind ~= "install" and ev.data.kind ~= "update" then
    return
  end

  if type(spec.build) == "function" then
    ensure_loaded(spec)
    spec.build(ev)
    return
  end

  if type(spec.build) ~= "string" then
    return
  end

  if spec.build:sub(1, 1) == ":" then
    ensure_loaded(spec)
    vim.cmd(spec.build:sub(2))
    return
  end

  local result = vim.system({ "sh", "-c", spec.build }, { cwd = ev.data.path }):wait()
  if result.code ~= 0 then
    local msg = ("build failed for %s"):format(spec.name)
    if result.stderr and #result.stderr > 0 then
      msg = msg .. ": " .. result.stderr
    end
    vim.notify(msg, vim.log.levels.ERROR)
  end
end

---@param plugins NgPluginSpec[]
local function register_build_hooks(plugins)
  ---@type table<string, NgPluginSpec>
  local by_name = {}
  for _, spec in ipairs(plugins) do
    if spec.build ~= nil then
      by_name[spec.name] = spec
    end
  end

  vim.api.nvim_create_autocmd("PackChanged", {
    group = vim.api.nvim_create_augroup("NgPackBuildHooks", { clear = true }),
    callback = function(ev)
      local spec = by_name[ev.data.spec.name]
      if spec ~= nil then
        run_build(spec, ev)
      end
    end,
  })
end

---@param plugins NgPluginSpec[]
---@param phase NgPluginPhase
local function setup_phase(plugins, phase)
  for _, spec in ipairs(plugins) do
    if spec.phase == phase then
      run_config(spec)
    end
  end
end

---@param plugins NgPluginSpec[]
function M.setup(plugins)
  local normalized = normalize_plugins(plugins)

  register_build_hooks(normalized)

  for _, spec in ipairs(normalized) do
    run_init(spec)
  end

  ---@type NgPackSpec[]
  local pack_specs = {}
  for _, spec in ipairs(normalized) do
    table.insert(pack_specs, spec._pack_spec)
  end

  vim.pack.add(pack_specs, { load = false, confirm = false })

  setup_phase(normalized, "core")

  vim.schedule(function()
    setup_phase(normalized, "ui")
  end)
end

return M
