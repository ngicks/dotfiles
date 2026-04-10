---@class NgPackUtil
local M = {}

-- return callable instance of given a
---@param a any
---@return function|table|nil
function M.callable(a)
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

---@param s string
---@param sep string
---@param n? integer
---@return string[]
function M.split(s, sep, n)
  if type(s) ~= "string" or s == "" then
    return {}
  end

  local t = {}
  local i = 0
  for ss in string.gmatch(s, "([^" .. sep .. "]+)") do
    table.insert(t, ss)
    i = i + 1
    if n == i then
      break
    end
  end

  if #t == 0 then
    return { s }
  end

  return t
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
