local wezterm = require("wezterm")

local get_host_name_from_pane = require("host-color").get_host_name_from_pane
local text_to_color = require("host-color").text_to_color

local M = {}

local function get_tab_title(tab)
	local title = tab.tab_title
	if title and #title > 0 then
		return title
	end
	return tab.active_pane.title
end

-- Format tab title with hostname-based colors
M.handler = function(tab, tabs, panes, config, hover, max_width)
	wezterm.log_info("format-tab-title")
	local hostname = get_host_name_from_pane(tab.active_pane)
	local title = get_tab_title(tab)

	local host_color = text_to_color(hostname)
	wezterm.log_info("host name: " .. hostname .. ", host_color: " .. host_color)

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
