local M = {}

-- Gets user_vars from either Pane object or PaneInformation table
-- See:
-- https://wezterm.org/config/lua/pane/index.html
-- https://wezterm.org/config/lua/PaneInformation.html
M.user_vars_from_pane_or_pane_info = function(paneOrPaneInfo)
	local success, result = pcall(function()
		return paneOrPaneInfo:get_user_vars()
	end)
	if success then
		return result
	end
	if paneOrPaneInfo.user_vars then
		return paneOrPaneInfo.user_vars
	end
	return nil
end

-- Collects all env_ prefixed user variables from a pane and returns
-- them as a table suitable for SpawnCommand's set_environment_variables.
-- The env_ prefix is stripped from the key names.
M.get_env_vars_for_spawn = function(paneOrPaneInfo)
	local user_vars = M.user_vars_from_pane_or_pane_info(paneOrPaneInfo) or {}
	local result = {}
	for key, value in pairs(user_vars) do
		if key:sub(1, 4) == "env_" and value ~= "" then
			local env_name = key:sub(5)
			result[env_name] = value
		end
	end
	return result
end

return M
