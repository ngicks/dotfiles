local wezterm = require("wezterm")

local sha256 = require("sha256").sha256

local M = {}

M.hostname_to_color = function(hostname)
	return "#" .. wezterm.truncate_right(sha256(hostname), 6)
end

local function trim(s)
	return s:match("^%s*(.-)%s*$")
end

M.get_hostname_from_pane = function(pane)
	if pane ~= nil then
		local user_vars = {}
		if pane.user_vars ~= nil then
			-- from PaneInfomation
			-- https://wezterm.org/config/lua/PaneInformation.html
			user_vars = pane.user_vars
		else
			-- from Pane
			-- https://wezterm.org/config/lua/pane/index.html
			local sucess, result = pcall(function()
				return pane:get_user_vars()
			end)
			if sucess then
				user_vars = result
			end
		end

		if user_vars.WEZTERM_HOST ~= nil and user_vars.WEZTERM_HOST ~= "" then
			wezterm.log_info("user_vars.WEZTERM_HOST: " .. trim(user_vars.WEZTERM_HOST))
			return trim(user_vars.WEZTERM_HOST)
		end

		local domain_name = pane.domain_name or ""
		if domain_name and domain_name:match("^SSH:") then
			-- lua is 1-indexed
			return domain_name:sub(5)
		end
	end

	return wezterm.hostname()
end

M.get_hostname_from_tab = function(tab)
	return M.get_hostname_from_pane(tab.active_pane or {})
end

M.host_color_from_pane = function(pane)
	return M.hostname_to_color(M.get_hostname_from_pane(pane))
end

M.host_color_from_tab = function(tab)
	return M.hostname_to_color(M.get_hostname_from_tab(tab))
end

M.hex_grb = function(bgColor)
	local r, g, b = bgColor:match("^#?(%x%x)(%x%x)(%x%x)$")
	assert(r, "invalid color, expected like #RRGGBB")
	return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end

M.text_color = function(bgColor)
	local r, g, b = M.hex_grb(bgColor)
	local brightness = ((r * 299 + g * 587 + b * 114) / 1000)
	if brightness > 128 then
		return "#101010"
	else
		return "#c0c0c0"
	end
end

return M
