local wezterm = require("wezterm")

local sha256 = require("sha256").sha256

local M = {}

local function hostname_to_color(hostname)
	return "#" .. wezterm.truncate_right(sha256(hostname), 6)
end

local function get_hostname_from_tab(tab)
	local user_vars = tab.active_pane.user_vars or {}

	if user_vars.WEZTERM_HOST ~= nil and user_vars.WEZTERM_HOST ~= "" then
		wezterm.log_info("user_vars.WEZTERM_HOST: " .. user_vars.WEZTERM_HOST)
		return user_vars.WEZTERM_HOST
	end

	local domain_name = tab.active_pane.domain_name
	if domain_name and domain_name:match("^SSH:") then
		-- lua is 1-indexed
		return domain_name:sub(5)
	end

	return wezterm.hostname()
end

local function get_tab_title(tab)
	local title = tab.tab_title
	if title and #title > 0 then
		return title
	end
	return tab.active_pane.title
end

-- Format tab title with hostname-based colors
M.handler = function(tab, tabs, panes, config, hover, max_width)
	local hostname = get_hostname_from_tab(tab)
	local title = get_tab_title(tab)

	local host_color = hostname_to_color(hostname)

	if #title > max_width - 6 then
		title = wezterm.truncate_right(title, max_width * 2 - 6) .. "..."
	end

	if tab.is_active then
		return {
			{ Foreground = { Color = host_color } },
			{ Text = "■" },
			{ Foreground = { Color = "white" } },
			{ Attribute = { Intensity = "Bold" } },
			{ Text = string.format(" %d", tab.tab_index + 1) },
			{ Background = { Color = "black" } },
			{ Foreground = { Color = "white" } },
			{ Text = ": " .. title .. " " },
		}
	else
		return {
			{ Foreground = { Color = host_color } },
			{ Text = "■" },
			{ Foreground = { Color = "#808080" } },
			{ Attribute = { Intensity = "Half" } },
			{ Text = string.format(" %d", tab.tab_index + 1) },
			{ Foreground = { Color = "#808080" } },
			{ Text = ": " .. title .. " " },
		}
	end
end

return M
