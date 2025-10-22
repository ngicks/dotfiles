local wezterm = require("wezterm")

local M = {}

M.handler = function(window, pane, name, value)
	wezterm.log_info("user-var-changed", name, value)
	wezterm.emit("update-status", window, pane, name, value)
end

return M
