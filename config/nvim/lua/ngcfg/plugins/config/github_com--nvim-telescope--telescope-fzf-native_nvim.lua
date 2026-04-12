---@type NgPackPluginConfigModule
local M = {}

---@param cwd string
local function build(cwd)
  require("ngpack.util").execute_shell("make", { cwd = cwd })
end

---@param spec NgPackSpec
local function library_path(spec)
  local sysname = vim.uv.os_uname().sysname
  local lib_name
  if sysname == "Darwin" then
    lib_name = "libfzf.dylib"
  elseif sysname:match "Windows" or sysname == "Windows_NT" then
    lib_name = "libfzf.dll"
  else
    lib_name = "libfzf.so"
  end
  return vim.fs.joinpath(require("ngpack.util").plug_dir(), spec:name(), "build", lib_name)
end

---@param spec NgPackSpec
---@return boolean
local function ensure_built(spec)
  local lib = library_path(spec)
  return vim.uv.fs_stat(lib) ~= nil
end

M.config = function(spec)
  if not ensure_built(spec) then
    vim.notify("telescope-fzf-native.nvim: native extension is not built yet", vim.log.levels.WARN)
    build(vim.fs.joinpath(require("ngpack.util").plug_dir(), spec:name()))
  end

  local ok, telescope = pcall(require, "telescope")
  if not ok then
    return
  end
  require "fzf_lib"
  local ok_ext, err = pcall(telescope.load_extension, "fzf")
  if not ok_ext then
    vim.notify("telescope-fzf-native.nvim: failed to load extension: " .. err, vim.log.levels.ERROR)
  end
end

M.pack_changed_pre = function(spec, data, ev)
  if data.kind ~= "update" then
    return
  end
  local lib = library_path(spec)
  local ok, err = vim.uv.fs_unlink(lib)
  if not ok then
    vim.notify(("removing %s failed: %s"):format(lib, err), vim.log.levels.ERROR)
  end
end

M.pack_changed = function(_s, data)
  vim.notify("PackChanged callback", vim.log.levels.INFO)

  if not data.active or data.kind == "delete" then
    return
  end

  build(data.path)
end

return M
