local M = {}

M.config = function()
   require("scrollbar").setup()
   require("scrollbar.handlers.gitsigns").setup()
end

return M
