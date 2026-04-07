local M = {}

M.opts = function()
  return {
    mounts = {
      base_dir = vim.fn.expand "$HOME" .. "/mnt/sshfs/", -- base directory for mount points
      unmount_on_exit = true, -- run sshfs as foreground, will unmount on vim exit
    },
  }
end

return M
