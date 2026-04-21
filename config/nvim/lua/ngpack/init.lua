---@class NgPackModule
local M = {}

local util = require "ngpack.util"

---@param src string
---@return string
local function repository_name(src)
  local tail = src:gsub("/+$", ""):match "([^/]+)$" or src
  local s = tail:gsub("%.git$", "")
  return s
end

---@param spec NgPackSpecPlain
---@return string
local function pack_name(spec)
  if spec.name then
    return spec.name
  end
  if type(spec.src) == "string" and spec.src ~= "" then
    return repository_name(spec.src)
  end
  error "plugin spec must contain src"
end

---@class NgPackSpec
---@field _p NgPackSpecPlain
---@field _opts? NgPackOpts
---@field _enable? boolean
---@field _initialized? boolean
---@field _configured? boolean
local NgPackSpec = {}
NgPackSpec.__index = NgPackSpec

M.NgPackSpec = NgPackSpec

---@param plain NgPackSpecPlain
---@return NgPackSpec
function NgPackSpec:new(plain)
  return setmetatable({ _p = vim.deepcopy(plain) }, NgPackSpec)
end

-- just unwrap. Editing returned plain spec is not advised.
---@return NgPackSpecPlain
function NgPackSpec:unwrap()
  return self._p
end

---@return vim.pack.Spec
function NgPackSpec:to_pack()
  return {
    src = self:src(),
    name = self:name(),
    version = self:version(),
    data = self:data(),
  }
end

---@return string
function NgPackSpec:src()
  return self._p.src
end

---@return string
function NgPackSpec:name()
  return self:pack_name()
end

---@return (string|vim.VersionRange)?
function NgPackSpec:version()
  if self._p.version ~= nil and self._p.version ~= "" then
    return self._p.version
  end
  return nil
end

---@return any?
function NgPackSpec:data()
  return self._p.data
end

---@return NgPackPhase
function NgPackSpec:phase()
  return self._p.phase or "ui"
end

---@return boolean
function NgPackSpec:enable()
  if self._enable ~= nil then
    return self._enable
  end

  local e = self._p.enable
  if e == nil then
    self._enable = true
    return self._enable
  end

  local c = util.callable(e)
  if c ~= nil then
    self._enable = c(self) and true or false
  else
    self._enable = e and true or false
  end

  return self._enable
end

---@return string name specified in a plain spec. or inferred from src.
function NgPackSpec:pack_name()
  return pack_name(self._p)
end

---@param spec NgPackSpecPlain
---@return NgPackOpts
local function pack_opts(spec)
  local c = util.callable(spec.opts)
  if c ~= nil then
    return c(spec)
  end
  return spec.opts
end

---@return NgPackOpts
function NgPackSpec:opts()
  if self._opts ~= nil then
    return self._opts
  end
  self._opts = pack_opts(self._p)
  return self._opts
end

function NgPackSpec:config() end

---@param spec NgPackSpecPlain
---@return string
local function pack_main_name(spec)
  if spec.main and spec.main ~= "" then
    return spec.main
  end

  local name = pack_name(spec)
  local s = name:gsub("%.nvim$", ""):gsub("%.lua$", ""):gsub("%.vim$", "")
  return s
end

-- returns inferred or specified main package name.
function NgPackSpec:main_name()
  return pack_main_name(self._p)
end

---@param spec NgPackSpecPlain
---@return any|nil
local function pack_require(spec)
  local main = pack_main_name(spec)
  local ok, mod = pcall(require, main)
  if not ok then
    vim.notify(("failed to require %s for %s: %s"):format(main, spec.name, mod), vim.log.levels.ERROR)
    return nil
  end
  return mod
end

function NgPackSpec:require()
  return pack_require(self._p)
end

---@param mod any
---@param spec NgPackSpec
---@param opts NgPackOpts
---@return boolean
local function call_setup(mod, spec, opts)
  local setup = util.callable(type(mod) == "table" and mod.setup or nil)
  if setup == nil then
    vim.notify(("missing callable setup() for %s"):format(spec:name()), vim.log.levels.WARN)
    return false
  end
  setup(opts)
  return true
end

function NgPackSpec:setup()
  if self._configured then
    return
  end

  local opts = self:opts()

  if type(self._p.config) == "function" then
    self._p.config(self, opts or {})
  elseif (self._p.config == true) or (opts ~= nil and self._p.config == nil) then
    local mod = self:require()
    if mod ~= nil then
      call_setup(mod, self, opts or {})
    end
  end

  self._configured = true
end

---@param specs NgPackSpecPlain[]
---@return NgPackSpec[]
local function from_plain(specs)
  ---@type NgPackSpec[]
  local mapped = {}
  ---@type table<string, boolean>
  local seen = {}
  for _, spec in ipairs(specs) do
    local name = repository_name(spec.src)
    if seen[name] then
      error("duplicate plugin name in plugins.list: " .. spec.name)
    end
    seen[name] = true
    table.insert(mapped, NgPackSpec:new(spec))
  end

  return mapped
end

M.from_plain = from_plain

---@param plugins NgPackSpec[]
local function register_pack_changed_hooks(plugins)
  ---@type table<string, NgPackSpec>
  local by_src_pre = {}
  ---@type table<string, NgPackSpec>
  local by_src_post = {}
  for _, spec in ipairs(plugins) do
    if spec._p.pack_changed_pre ~= nil then
      by_src_pre[spec:src()] = spec
    end
    if spec._p.pack_changed ~= nil then
      by_src_post[spec:src()] = spec
    end
  end

  ---@param pre boolean
  ---@param spec NgPackSpec
  ---@param ev vim.api.keyset.create_autocmd.callback_args
  local call_cb = function(pre, spec, ev)
    local cb = (pre and spec._p.pack_changed_pre) or (not pre and spec._p.pack_changed) or nil
    if cb == nil then
      return
    end
    local ok, err = pcall(function()
      cb(spec, ev.data, ev)
    end)
    if not ok then
      vim.notify(
        ("callback failed: package %s, event = %s, err = %s"):format(spec:src(), ev.event, err),
        vim.log.levels.ERROR
      )
    end
  end

  vim.api.nvim_create_autocmd("PackChangedPre", {
    group = vim.api.nvim_create_augroup("NgPackPackChangedPreHooks", { clear = true }),
    callback = function(ev)
      -- https://neovim.io/doc/user/pack/#PackChanged
      ---@type vim.pack.Spec
      local raw_spec = ev.data.spec
      local spec = by_src_pre[raw_spec.src]
      if spec ~= nil then
        call_cb(true, spec, ev)
      end
    end,
  })

  vim.api.nvim_create_autocmd("PackChanged", {
    group = vim.api.nvim_create_augroup("NgPackPackChangedHooks", { clear = true }),
    callback = function(ev)
      ---@type vim.pack.Spec
      local raw_spec = ev.data.spec
      local spec = by_src_post[raw_spec.src]
      if spec ~= nil then
        call_cb(false, spec, ev)
      end
    end,
  })
end

---@param spec NgPackSpec
local function run_init(spec)
  if spec._initialized then
    return
  end

  if type(spec._p.init) == "function" then
    spec._p.init(spec)
  end

  spec._initialized = true
end

---@param plugins NgPackSpec[]
---@param phase NgPackPhase
local function setup_phase(plugins, phase)
  for _, spec in ipairs(plugins) do
    if spec:phase() == phase then
      spec:setup()
    end
  end
end

local already_setup = false
---@type NgPackSpec[]
local ngpacks = {}
---@type table<string, NgPackSpec>
local lazy_specs = {}

---@param specs NgPackSpecPlain[]
local function setup(specs)
  if already_setup then
    return
  end

  ngpacks = from_plain(specs)

  -- ngpacks keeps every declared plugin (so list_pack() still sees disabled
  -- plugins and their on-disk dirs are not treated as orphans). enabled drives
  -- actual loading: pack.add, init, setup, pack_changed hooks, lazy map.
  ---@type NgPackSpec[]
  local enabled = {}
  for _, spec in ipairs(ngpacks) do
    if spec:enable() then
      table.insert(enabled, spec)
    end
  end

  for _, spec in ipairs(enabled) do
    if spec:phase() == "lazy" then
      lazy_specs[spec:main_name()] = spec
    end
  end

  register_pack_changed_hooks(enabled)

  for _, spec in ipairs(enabled) do
    run_init(spec)
  end

  ---@type vim.pack.Spec[]
  local pack_specs = {}
  for _, spec in ipairs(enabled) do
    table.insert(pack_specs, spec:to_pack())
  end

  vim.pack.add(pack_specs, { confirm = false })

  setup_phase(enabled, "core")

  vim.schedule(function()
    setup_phase(enabled, "ui")
  end)

  local lock = require "ngpack.lock"
  lock.setup_user_command()
  if lock.should_auto_report() then
    vim.schedule(function()
      lock.report_desync(false)
    end)
  end
  already_setup = true
end

M.setup = setup

-- Load phase == "lazy" packs manually with setup function called.
---@param name string
---@param main_package_name? string
local function load(name, main_package_name)
  local mod_name = util.split(name, ".", 1)

  local spec_name = (main_package_name ~= nil and main_package_name ~= "" and main_package_name)
    or (#mod_name > 0 and mod_name[1])
    or ""
  if spec_name ~= "" then
    local spec = lazy_specs[spec_name]
    if spec ~= nil then
      spec:setup()
    end
  end

  return require(name)
end

M.load = load

---@return vim.pack.Spec[]
local function list_pack()
  local packs = {}
  for _, spec in ipairs(ngpacks) do
    table.insert(packs, spec:to_pack())
  end
  return packs
end

M.list_pack = list_pack

return M
