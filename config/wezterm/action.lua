local wezterm = require("wezterm")
local gpu = require("gpu")

local M = {}

M.toggle_background_opacity = wezterm.action_callback(function(win, pane)
	local overrides = win:get_config_overrides() or {}
	local new_cfg = gpu.get_toggled_config(overrides.window_background_opacity)

	overrides.window_background_opacity = new_cfg.window_background_opacity
	if gpu.is_windows then
		overrides.win32_system_backdrop = new_cfg.win32_system_backdrop
	elseif gpu.is_macos then
		overrides.macos_window_background_blur = new_cfg.macos_window_background_blur
	elseif gpu.is_kde and gpu.is_nightly then
		overrides.kde_window_background_blur = new_cfg.kde_window_background_blur
	end
	-- Other Linux: opacity only

	win:set_config_overrides(overrides)
end)

return M
