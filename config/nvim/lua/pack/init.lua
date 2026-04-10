---@class NgPackModule
local M = {}

local util = require "pack.util"

---@param spec NgPackSpecPlain
local function pack_version(spec)
  if spec.version ~= nil and spec.version ~= "" then
    return spec.version
  end
  if spec.branch ~= nil and spec.branch ~= "" then
    return spec.branch
  end
  if spec.commit ~= nil and spec.commit ~= "" then
    return spec.commit
  end
end

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
---@field _loaded? boolean
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

---@return string?
function NgPackSpec:name()
  return self._p.name
end

---@return (string|vim.VersionRange)?
function NgPackSpec:version()
  return pack_version(self._p)
end

---@return any?
function NgPackSpec:data()
  return self._p.data
end

---@return NgPackPhase
function NgPackSpec:phase()
  return self._p.phase or "ui"
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

function NgPackSpec:ensure_loaded()
  if self._loaded then
    return
  end

  vim.cmd("packadd " .. vim.fn.fnameescape(self:pack_name()))
  self._loaded = true
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

  self:ensure_loaded()

  local opts = self:opts()

  if type(self._p.config) == "function" then
    self._p.config(self._p, opts or {})
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

---@param spec NgPackSpec
---@param ev  vim.api.keyset.create_autocmd.callback_args
local function run_build(spec, ev)
  if spec._p.build == nil then
    return
  end

  if ev.data.kind ~= "install" and ev.data.kind ~= "update" then
    return
  end

  local build = spec._p.build

  if type(build) == "function" then
    spec:ensure_loaded()
    build(ev)
    return
  end

  if type(build) ~= "string" then
    return
  end

  if build:sub(1, 1) == ":" then
    spec:ensure_loaded()
    vim.cmd(build:sub(2))
    return
  end

  local result = vim.system({ "sh", "-c", build }, { cwd = ev.data.path }):wait()
  if result.code ~= 0 then
    local msg = ("build failed for %s"):format(spec.name)
    if result.stderr and #result.stderr > 0 then
      msg = msg .. ": " .. result.stderr
    end
    vim.notify(msg, vim.log.levels.ERROR)
  end
end

---@param plugins NgPackSpec[]
local function register_build_hooks(plugins)
  ---@type table<string, NgPackSpec>
  local by_src = {}
  for _, spec in ipairs(plugins) do
    if spec._p.build ~= nil then
      by_src[spec:src()] = spec
    end
  end

  vim.api.nvim_create_autocmd("PackChanged", {
    group = vim.api.nvim_create_augroup("NgPackBuildHooks", { clear = true }),
    callback = function(ev)
      -- https://neovim.io/doc/user/pack/#PackChanged
      ---@type vim.pack.Spec
      local raw_spec = ev.data.spec
      local spec = by_src[raw_spec.src]
      if spec ~= nil then
        run_build(spec, ev)
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
    spec._p.init(spec._p)
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

  for _, spec in ipairs(ngpacks) do
    if spec:phase() == "lazy" then
      lazy_specs[spec:main_name()] = spec
    end
  end

  register_build_hooks(ngpacks)

  for _, spec in ipairs(ngpacks) do
    run_init(spec)
  end

  ---@type vim.pack.Spec[]
  local pack_specs = {}
  for _, spec in ipairs(ngpacks) do
    table.insert(pack_specs, spec:to_pack())
  end

  vim.pack.add(pack_specs, { load = false, confirm = false })

  setup_phase(ngpacks, "core")

  vim.schedule(function()
    setup_phase(ngpacks, "ui")
  end)

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

return M
