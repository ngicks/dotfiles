local M = {}

M.config = function()
  require "fzf_lib"
  require("telescope").load_extension "fzf"
end

M.build = "make"

return M
