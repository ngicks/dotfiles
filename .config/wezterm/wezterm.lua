local wezterm = require("wezterm")

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

return config
