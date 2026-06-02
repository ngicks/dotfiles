{ config, ... }:
{
  xdg.configFile."cmdman" = {
    source = ../../../config/cmdman;
    recursive = true;
  };
}
