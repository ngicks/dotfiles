local M = {}

local function ensure_built()
  local sysname = vim.uv.os_uname().sysname
  local lib_name
  if sysname == "Darwin" then
    lib_name = "libfzf.dylib"
  elseif sysname:match "Windows" or sysname == "Windows_NT" then
    lib_name = "libfzf.dll"
  else
    lib_name = "libfzf.so"
  end
  local root = require("lazy.core.config").options.root .. "/telescope-fzf-native.nvim"
  local lib = root .. "/build/" .. lib_name

  if vim.uv.fs_stat(lib) then
    return true
  end

  if vim.fn.executable "make" == 0 then
    vim.notify("telescope-fzf-native.nvim: missing `make`; skip native extension build", vim.log.levels.WARN)
    return false
  end

  vim.notify("telescope-fzf-native.nvim: building native extension…", vim.log.levels.INFO)

  local ok, result
  if vim.system then
    result = vim.system({ "make" }, { cwd = root }):wait()
    ok = result.code == 0
  else
    local job = vim.fn.jobstart({ "make" }, { cwd = root })
    if job <= 0 then
      ok = false
    else
      ok = vim.fn.jobwait({ job })[1] == 0
    end
  end

  if not ok then
    local msg = "telescope-fzf-native.nvim: build failed"
    if result and result.stderr and #result.stderr > 0 then
      msg = msg .. ": " .. table.concat(result.stderr, "\n")
    end
    vim.notify(msg, vim.log.levels.ERROR)
    return false
  end

  if vim.uv.fs_stat(lib) then
    vim.notify("telescope-fzf-native.nvim: native extension ready", vim.log.levels.INFO)
    return true
  end

  vim.notify("telescope-fzf-native.nvim: build completed but " .. lib_name .. " missing", vim.log.levels.WARN)
  return false
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
  end
end

M.build = "make"

return M
