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

-- returns #101010 or #c0c0c0
-- based on brightness computed from bgColor.
-- bgColor must follow "#ffffff" format.
-- The formula follow one shown in https://www.w3.org/TR/AERT/
-- Technique 2.2.1 [priority 3] Test the color attributes of the following elements for visibility
M.foreground_color = function(bgColor)
	local r, g, b = M.hex_grb(bgColor)
	local brightness = ((r * 299 + g * 587 + b * 114) / 1000)
	if brightness > 128 then
		return "#101010"
	else
		return "#c0c0c0"
	end
end

-- Props that counter part of PaneInformation has get_ method for them.
-- see https://wezterm.org/config/lua/PaneInformation.html
local _get_keys = {
	current_working_dir = true,
	cursor_position = true,
	dimensions = true,
	domain_name = true,
	foreground_process_info = true,
	foreground_process_name = true,
	lines_as_escapes = true,
	lines_as_text = true,
	logical_lines_as_text = true,
	metadata = true,
	progress = true,
	semantic_zone_at = true,
	semantic_zones = true,
	text_from_region = true,
	text_from_semantic_zone = true,
	title = true,
	tty_name = true,
	user_vars = true,
}

-- see
-- https://wezterm.org/config/lua/PaneInformation.html
-- and
-- https://wezterm.org/config/lua/PaneInformation.html
M.get_from_pane_or_pane_info = function(paneOrPaneInfo, propName)
	if _get_keys[propName] then
		local sucess, result = pcall(function()
			return paneOrPaneInfo["get_" + propName](paneOrPaneInfo)
		end)
		if sucess then
			return result
		end
	elseif paneOrPaneInfo[propName] then
		return paneOrPaneInfo[propName]
	end
	return nil
end

local function trim(s)
	return s:match("^%s*(.-)%s*$")
end

-- gets user_vars.WEZTERM_HOST and returns it.
-- If not set, falls back to wezterm.hostname()
M.get_host_name_from_pane = function(paneOrPaneInfo)
	local user_vars = M.get_from_pane_or_pane_info(paneOrPaneInfo, "user_vars") or {}
	if user_vars.WEZTERM_HOST ~= nil and user_vars.WEZTERM_HOST ~= "" then
		wezterm.log_info("user_vars.WEZTERM_HOST: " .. trim(user_vars.WEZTERM_HOST))
		return trim(user_vars.WEZTERM_HOST)
	end

	local domain_name = M.get_from_pane_or_pane_info(paneOrPaneInfo, "domain_name") or ""
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
