local M = {}

local function repo_tail(src)
  local tail = src:gsub("/+$", ""):match "([^/]+)$" or src
  return tail:gsub("%.git$", "")
end

function M.plugin_name(spec)
  if spec.name then
    return spec.name
  end
  if type(spec.src) == "string" and spec.src ~= "" then
    return repo_tail(spec.src)
  end
  error "plugin spec must contain src"
end

function M.plugin_src(spec)
  local src = spec.src
  if type(src) == "string" and src:find("://", 1, true) then
    return src
  end
  error "plugin spec must contain full src URL"
end

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

function M.phase(spec)
  return spec.phase or "ui"
end

function M.spec_to_pack(spec)
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

function M.infer_main(spec)
  if spec.main then
    return spec.main
  end

  local name = M.plugin_name(spec)
  return name:gsub("%.nvim$", ""):gsub("%.lua$", ""):gsub("%.vim$", "")
end

function M.plugin_dir(name)
  local base = vim.fn.stdpath "data" .. "/site/pack"
  local results = vim.fn.globpath(base, "*/*/" .. name, false, true)
  return results[1]
end

return M
