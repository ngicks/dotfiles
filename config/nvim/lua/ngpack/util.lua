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

---@return string
function M.plug_dir()
  return vim.fs.joinpath(vim.fn.stdpath "data", "site", "pack", "core", "opt")
end

-- Executes a shell command using the environemnt's shell(`$SHELL`) or `sh`.
---@param command string
---@param opts vim.SystemOpts?
---@param on_exit? fun(out: vim.SystemCompleted) when provided, command runs asynchronously without :wait call
---                and execute_shell returns true immediately
---@return boolean
function M.execute_shell(command, opts, on_exit)
  local shell = vim.env.SHELL
  if shell == nil or shell == "" then
    shell = "sh"
  end

  local proc = vim.system({ shell, "-c", command }, opts, on_exit)

  if on_exit ~= nil then
    return true
  end

  local result = proc:wait()
  if result.code ~= 0 then
    local msg = ("command failed: %s"):format(command)
    if result.stderr and #result.stderr > 0 then
      msg = msg .. ": " .. result.stderr
    end
    vim.notify(msg, vim.log.levels.ERROR)
    return false
  end

  return true
end

return M
