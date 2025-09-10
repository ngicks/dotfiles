local wezterm = require("wezterm")

local sha256 = require("sha256").sha256

local config = wezterm.config_builder()

if #(wezterm.default_wsl_domains()) > 0 then
	config.default_domain = wezterm.default_wsl_domains()[1].name
end

-- remove windows bar
config.window_decorations = "RESIZE"
-- remove "+" button in tab bar
config.show_new_tab_button_in_tab_bar = false

-- fonts
config.font = wezterm.font("BitstromWera Nerd Font Mono")
config.font_size = 11

-- color
config.color_scheme = "Tokyo Night"

-- alerts
-- Hate noises when pressing tab in shells.
-- I might improve this later not just disabling all sounds, but disallow ringing bells when tabs/command fail, etc.
config.audible_bell = "Disabled"

-- keys
config.leader = { key = " ", mods = "SHIFT|CTRL|ALT", timeout_milliseconds = 1000 }

config.keys = require("keybinds").keys
config.key_tables = require("keybinds").key_tables

-- Function to generate color from hostname (similar to tmux setup)
local function hostname_to_color(hostname)
	return "#" .. wezterm.truncate_right(sha256(hostname), 6)
end

-- Function to get hostname from tab
local function get_hostname_from_tab(tab)
	-- Try to get hostname from user vars (requires shell integration)
	local success, user_vars = pcall(function()
		return tab.active_pane.user_vars
	end)

	if success and user_vars and user_vars.WEZTERM_HOST then
		wezterm.log_info("user_vars.WEZTERM_HOST: " .. user_vars.WEZTERM_HOST)
		return user_vars.WEZTERM_HOST
	end

	-- Check if it's an SSH domain
	local domain_name = tab.active_pane.domain_name
	if domain_name and domain_name:match("^SSH:") then
		-- Extract hostname from SSH:hostname format
		return domain_name:sub(5)
	end

	-- Fallback to local hostname
	return wezterm.hostname()
end

-- Function to get tab title
local function get_tab_title(tab)
	local title = tab.tab_title
	-- If there's a custom title, use it
	if title and #title > 0 then
		return title
	end
	-- Otherwise use the active pane title
	return tab.active_pane.title
end

-- Format tab title with hostname-based colors
-- https://wezterm.org/config/lua/window-events/format-tab-title.html
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local hostname = get_hostname_from_tab(tab)
	local title = get_tab_title(tab)

	-- Generate colors based on hostname
	local host_color = hostname_to_color(hostname)

	-- Truncate if too long
	if #title > max_width - 6 then
		title = wezterm.truncate_right(title, max_width * 2 - 6) .. "..."
	end

	-- Apply different styling for active vs inactive tabs
	-- Show colored box next to tab number instead of coloring entire tab
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
		-- Make inactive tabs slightly dimmer
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
end)

return config
