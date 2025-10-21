local wezterm = require("wezterm")

local host_color_from_pane = require("host-color").host_color_from_pane
local text_color = require("host-color").text_color

local M = {}

local function get_hostname(pane)
	local hostname = ""
	-- Figure out the cwd and host of the current pane.
	-- This will pick up the hostname for the remote host if your
	-- shell is using OSC 7 on the remote host.
	local cwd_uri = pane:get_current_working_dir()
	if cwd_uri then
		if type(cwd_uri) == "userdata" then
			-- Running on a newer version of wezterm and we have
			-- a URL object here, making this simple!
			hostname = cwd_uri.host or wezterm.hostname()
		else
			-- an older version of wezterm, 20230712-072601-f4abf8fd or earlier,
			-- which doesn't have the Url object
			cwd_uri = cwd_uri:sub(8)
			local slash = cwd_uri:find("/")
			if slash then
				hostname = cwd_uri:sub(1, slash - 1)
			end
		end

		-- Remove the domain name portion of the hostname
		local dot = hostname:find("[.]")
		if dot then
			hostname = hostname:sub(1, dot - 1)
		end
		if hostname == "" then
			hostname = wezterm.hostname()
		end
	end

	return hostname
end

M.handler = function(window, pane, name, value)
	local cells = {
		{ text = window:active_workspace() },
		{ text = get_hostname(pane), color = host_color_from_pane(window:active_pane() or {}) },
		{ text = wezterm.strftime("%a %b %-d %H:%M:%S") },
	}

	-- An entry for each battery (typically 0 or 1 battery)
	for _, b in ipairs(wezterm.battery_info()) do
		table.insert(cells, string.format("%.0f%%", b.state_of_charge * 100))
	end

	-- The filled in variant of the < symbol
	local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

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
		{ Text = SOLID_LEFT_ARROW },
	}

	local cursor = 1

	for i, cell in ipairs(cells) do
		local color = cell.color
		if color == nil then
			color = get_color(cursor)
			cursor = cursor + 1
		end

		if i > 1 then
			table.insert(elements, { Attribute = { Intensity = "Bold" } })
			table.insert(elements, { Foreground = { Color = color } })
			table.insert(elements, { Text = SOLID_LEFT_ARROW })
		end
		table.insert(elements, { Attribute = { Intensity = "Normal" } })
		table.insert(elements, { Background = { Color = color } })
		table.insert(elements, { Foreground = { Color = text_color(color) } })
		table.insert(elements, { Text = " " .. cell.text .. " " })
	end

	window:set_right_status(wezterm.format(elements))
end

return M
