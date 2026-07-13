---@type NgPackPluginConfigModule
local M = {}

M.opts = function()
  local base_dir = vim.fn.expand "$HOME" .. "/mnt/sshfs/" -- base directory for mount points
  -- the plugin creates base_dir with a non-recursive mkdir, which errors at
  -- every startup on a fresh machine where ~/mnt does not exist yet.
  vim.fn.mkdir(base_dir, "p")
  return {
    mounts = {
      base_dir = base_dir,
      unmount_on_exit = true, -- run sshfs as foreground, will unmount on vim exit
    },
  }
end

return M
