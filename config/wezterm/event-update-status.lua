local wezterm = require("wezterm")

local get_host_name_from_pane = require("host-color").get_host_name_from_pane
local text_to_color = require("host-color").text_to_color
local contrast_color = require("host-color").contrast_color

local M = {}

local function normalize_hostname(hostname, n)
	-- It's not monospace font or white spaces are squashed.
	-- But anyway just regulate host name length
	if #hostname > n then
		return wezterm.truncate_right(hostname, n - 3) .. "..."
	end
	if #hostname == n then
		return hostname
	end
	local diff = n - #hostname
	local half = math.floor(diff / 2)
	local s = string.rep(" ", half) .. hostname .. string.rep(" ", half)
	if diff % 2 ~= 0 then
		s = " " .. s
	end
	return s
end

M.handler = function(window, pane, name, value)
	wezterm.log_info("update-status", name, value)
	local hostname = get_host_name_from_pane(pane)
	local cells = {
		{ text = window:active_workspace() },
		{ text = normalize_hostname(hostname, 16), color = text_to_color(hostname) },
		{ text = wezterm.strftime("%a %b %-d %H:%M:%S") },
	}

	-- An entry for each battery (typically 0 or 1 battery)
	for _, b in ipairs(wezterm.battery_info()) do
		table.insert(cells, { text = string.format("%.0f%%", b.state_of_charge * 100) })
	end

	-- The filled in variant of the < symbol
	local LEFT_CIRCLE = wezterm.nerdfonts.ple_left_half_circle_thick

	-- Color palette for the backgrounds of each cell
	local colors = {
		"#103D14",
		"#27692E",
		"#448546",
		"#76914C",
		"#91894C",
		"#8F7B51",
	}
	local function get_color(i)
		if i < 1 then
			return colors[1]
		elseif #colors < i then
			return colors[#colors]
		end
		return colors[i]
	end

	-- Foreground color for the text across the fade

	-- The elements to be formatted
	local elements = {
		{ Attribute = { Intensity = "Bold" } },
		{ Background = { Color = "none" } },
		{ Foreground = { Color = colors[1] } },
		{ Text = LEFT_CIRCLE },
	}

	local cursor = 1

	for i, cell in ipairs(cells) do
		local bgColor = cell.color
		local fgColor
		if bgColor ~= nil then
			fgColor = bgColor
			bgColor = contrast_color(bgColor)
		else
			bgColor = get_color(cursor)
			fgColor = contrast_color(bgColor)
			cursor = cursor + 1
		end

		if i > 1 then
			table.insert(elements, { Attribute = { Intensity = "Bold" } })
			table.insert(elements, { Foreground = { Color = bgColor } })
			table.insert(elements, { Text = LEFT_CIRCLE })
		end
		table.insert(elements, { Attribute = { Intensity = "Normal" } })
		table.insert(elements, { Background = { Color = bgColor } })
		table.insert(elements, { Foreground = { Color = fgColor } })
		table.insert(elements, { Text = " " .. cell.text .. " " })
	end

	window:set_right_status(wezterm.format(elements))
end

return M
