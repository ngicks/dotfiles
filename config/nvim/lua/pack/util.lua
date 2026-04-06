local M = {}

local function repo_tail(src)
  local tail = src:gsub("/+$", ""):match "([^/]+)$" or src
  return tail:gsub("%.git$", "")
end

function M.plugin_name(spec)
  if spec.name then
    return spec.name
  end
  if type(spec[1]) == "string" then
    return repo_tail(spec[1])
  end
  return repo_tail(spec.src)
end

function M.plugin_src(spec)
  local src = spec.src or spec[1]
  if src:find("://", 1, true) or src:find "^git@" or src:find "^[%w.+-]+:" then
    return src
  end
  return "https://github.com/" .. src
end

function M.plugin_version(spec)
  if spec.version ~= nil then
    return spec.version
  end
  if spec.branch ~= nil then
    return spec.branch
  end
  if spec.commit ~= nil then
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
