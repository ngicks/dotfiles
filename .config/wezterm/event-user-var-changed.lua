local wezterm = require("wezterm")

local M = {}

M.handler = function(window, pane, name, value)
	wezterm.log_info("var", name, value)
end

return M
