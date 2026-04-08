---@class NgPackUtil
local M = {}

---@param src string
---@return string
local function repo_tail(src)
  local tail = src:gsub("/+$", ""):match "([^/]+)$" or src
  return tail:gsub("%.git$", "")
end

---@param spec NgPluginSpec
---@return string
function M.plugin_name(spec)
  if spec.name then
    return spec.name
  end
  if type(spec.src) == "string" and spec.src ~= "" then
    return repo_tail(spec.src)
  end
  error "plugin spec must contain src"
end

---@param spec NgPluginSpec
---@return string
function M.plugin_src(spec)
  local src = spec.src
  if type(src) == "string" and src:find("://", 1, true) then
    return src
  end
  error "plugin spec must contain full src URL"
end

---@param spec NgPluginSpec
---@return NgPluginVersion|string|nil
function M.plugin_version(spec)
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

---@param spec NgPluginSpec
---@return NgPluginPhase
function M.phase(spec)
  return spec.phase or "ui"
end

---@param spec NgPluginSpec
---@return NgPackSpec
function M.spec_to_pack(spec)
  ---@type NgPackSpec
  local pack_spec = {
    src = M.plugin_src(spec),
    name = M.plugin_name(spec),
  }

  local version = M.plugin_version(spec)
  if version ~= nil then
    pack_spec.version = version
  end
  return pack_spec
end

---@param spec NgPluginSpec
---@return string
function M.infer_main(spec)
  if spec.main then
    return spec.main
  end

  local name = M.plugin_name(spec)
  return name:gsub("%.nvim$", ""):gsub("%.lua$", ""):gsub("%.vim$", "")
end

---@param name string
---@return string|nil
function M.plugin_dir(name)
  local base = vim.fn.stdpath "data" .. "/site/pack"
  ---@type string[]
  local results = vim.fn.globpath(base, "*/*/" .. name, false, true)
  return results[1]
end

return M
