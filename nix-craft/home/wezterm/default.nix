{ config, ... }:
{
  xdg.configFile."wezterm" = {
    source = ../../../config/wezterm;
    recursive = true;
  };
}
