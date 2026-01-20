local wezterm = require("wezterm")
local M = {}

-- Platform detection
M.is_windows = wezterm.target_triple:find("windows") ~= nil
M.is_macos = wezterm.target_triple:find("darwin") ~= nil
M.is_linux = wezterm.target_triple:find("linux") ~= nil

-- Desktop environment detection (for Linux)
local xdg_desktop = os.getenv("XDG_CURRENT_DESKTOP") or ""
M.is_kde = xdg_desktop:find("KDE") ~= nil

-- Nightly detection
M.is_nightly = wezterm.version:find("nightly") ~= nil

-- GPU detection with pcall for safety
local function detect_discrete_gpu()
	local ok, gpus = pcall(function()
		return wezterm.gui.enumerate_gpus()
	end)
	if not ok or not gpus then
		return false
	end
	for _, gpu in ipairs(gpus) do
		if gpu.device_type == "DiscreteGpu" then
			return true
		end
	end
	return false
end

M.has_discrete_gpu = detect_discrete_gpu()

-- Get default config based on platform and GPU
function M.get_default_config()
	if not M.has_discrete_gpu then
		-- No discrete GPU: fully opaque, no effects
		return {
			window_background_opacity = 1.0,
			win32_system_backdrop = "Disable",
			macos_window_background_blur = 0,
			kde_window_background_blur = false,
		}
	end
	-- Has discrete GPU: enable transparency and effects
	return {
		window_background_opacity = 0.7,
		win32_system_backdrop = "Acrylic",
		macos_window_background_blur = 10,
		kde_window_background_blur = true,
	}
end

-- Get toggled config based on platform and GPU
function M.get_toggled_config(current_opacity)
	local default_cfg = M.get_default_config()
	local is_at_default = current_opacity == nil or current_opacity == default_cfg.window_background_opacity

	if not M.has_discrete_gpu then
		-- Non-GPU: toggle between 1.0 and 0.75
		if is_at_default then
			return {
				window_background_opacity = 0.75,
				win32_system_backdrop = "Disable",
				macos_window_background_blur = 0,
				kde_window_background_blur = false,
			}
		else
			return {
				window_background_opacity = 1.0,
				win32_system_backdrop = "Disable",
				macos_window_background_blur = 0,
				kde_window_background_blur = false,
			}
		end
	end

	-- GPU: toggle between transparent+effects and semi-opaque+no effects
	if is_at_default then
		return {
			window_background_opacity = 0.75,
			win32_system_backdrop = "Disable",
			macos_window_background_blur = 0,
			kde_window_background_blur = false,
		}
	else
		return {
			window_background_opacity = 0.7,
			win32_system_backdrop = "Acrylic",
			macos_window_background_blur = 10,
			kde_window_background_blur = true,
		}
	end
end

return M
