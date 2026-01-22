local wezterm = require("wezterm")

local sha256 = require("sha256").sha256

local M = {}

-- converts text to a deterministic color.
M.text_to_color = function(t)
	return "#" .. wezterm.truncate_right(sha256(t), 6)
end

-- hex_grb returns 3 numbers extracted from c.
-- c must be string formatted as "#ffffff"
M.hex_grb = function(c)
	local r, g, b = c:match("^#?(%x%x)(%x%x)(%x%x)$")
	assert(r, "invalid color, expected like #RRGGBB")
	return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end

-- returns #1e1c3c or #c0c0c0
-- based on brightness computed from c.
-- c must follow "#ffffff" format.
-- The formula follow one shown in https://www.w3.org/TR/AERT/
-- Technique 2.2.1 [priority 3] Test the color attributes of the following elements for visibility
M.contrast_color = function(c)
	local r, g, b = M.hex_grb(c)
	local brightness = ((r * 299 + g * 587 + b * 114) / 1000)
	if brightness > 128 then
		return "#1e1c3c"
	else
		return "#c0c0c0"
	end
end

-- see
-- https://wezterm.org/config/lua/PaneInformation.html
-- and
-- https://wezterm.org/config/lua/PaneInformation.html
M.user_vars_from_pane_or_pane_info = function(paneOrPaneInfo)
	-- p["get_"..propName](p) did not work well somehow.
	-- I'll keep doing this dirty copy-pasting until I can find a fix.
	local sucess, result = pcall(function()
		return paneOrPaneInfo:get_user_vars()
	end)
	if sucess then
		return result
	end
	if paneOrPaneInfo.user_vars then
		return paneOrPaneInfo.user_vars
	end
	return nil
end

M.domain_name_from_pane_or_pane_info = function(paneOrPaneInfo)
	local sucess, result = pcall(function()
		return paneOrPaneInfo:get_domain_name()
	end)
	if sucess then
		return result
	end
	if paneOrPaneInfo.domain_name then
		return paneOrPaneInfo.domain_name
	end
	return nil
end

local function trim(s)
	return s:match("^%s*(.-)%s*$")
end

-- gets user_vars.WEZTERM_HOST and returns it.
-- If not set, falls back to wezterm.hostname()
M.get_host_name_from_pane = function(paneOrPaneInfo)
	local user_vars = M.user_vars_from_pane_or_pane_info(paneOrPaneInfo) or {}
	if user_vars.WEZTERM_HOST ~= nil and user_vars.WEZTERM_HOST ~= "" then
		wezterm.log_info("user_vars.WEZTERM_HOST: " .. trim(user_vars.WEZTERM_HOST))
		return trim(user_vars.WEZTERM_HOST)
	end

	local domain_name = M.domain_name_from_pane_or_pane_info(paneOrPaneInfo) or ""
	if domain_name and domain_name:match("^SSH:") then
		-- lua is 1-indexed
		return domain_name:sub(5)
	end

	return wezterm.hostname()
end

M.get_color_from_host_name_from_pane = function(pane)
	return M.text_to_color(M.get_host_name_from_pane(pane))
end

return M
