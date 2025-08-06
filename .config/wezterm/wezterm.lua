-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end


config.default_domain = 'WSL:Ubuntu-24.04'

config.font = wezterm.font 'BitstromWera Nerd Font Mono'
config.font_size = 11

-- For example, changing the color scheme:
config.color_scheme = 'Tokyo Night'

-- and finally, return the configuration to wezterm
return config