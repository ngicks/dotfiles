local wezterm = require("wezterm")

local M = {}

M.commands = function()
	return {
		{
			brief = "Toggle Window Opacity",
			icon = "md_circle_opacity",
			action = wezterm.action_callback(function(win, pane)
				local overrides = win:get_config_overrides() or {}
				local current = overrides.window_background_opacity or 1.0
				if current < 1.0 then
					overrides.window_background_opacity = 1.0
				else
					overrides.window_background_opacity = 0.75
				end
				win:set_config_overrides(overrides)
			end),
		},
	}
end

return M
