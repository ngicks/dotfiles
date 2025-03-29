local M = {}

M.config = function()
  require("telescope").load_extension "fzf"
end

M.build = "make"

return M
