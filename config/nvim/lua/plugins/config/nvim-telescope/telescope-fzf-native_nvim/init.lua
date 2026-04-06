local M = {}

local function library_path()
  local sysname = vim.uv.os_uname().sysname
  local lib_name
  if sysname == "Darwin" then
    lib_name = "libfzf.dylib"
  elseif sysname:match "Windows" or sysname == "Windows_NT" then
    lib_name = "libfzf.dll"
  else
    lib_name = "libfzf.so"
  end
  local root = require("pack.util").plugin_dir("telescope-fzf-native.nvim")
  if not root then
    return nil
  end
  return root .. "/build/" .. lib_name
end

local function ensure_built()
  local lib = library_path()
  return lib ~= nil and vim.uv.fs_stat(lib) ~= nil
end

M.config = function()
  if ensure_built() then
    local ok, telescope = pcall(require, "telescope")
    if not ok then
      return
    end
    require "fzf_lib"
    local ok_ext, err = pcall(telescope.load_extension, "fzf")
    if not ok_ext then
      vim.notify("telescope-fzf-native.nvim: failed to load extension: " .. err, vim.log.levels.ERROR)
    end
  else
    vim.notify("telescope-fzf-native.nvim: native extension is not built yet", vim.log.levels.WARN)
  end
end

M.build = "make"

return M
