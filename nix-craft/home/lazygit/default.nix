{ config, pkgs, ... }:
{
  programs.lazygit = {
    enable = true;
    enableZshIntegration = true;
  };
  xdg.configFile."lazygit" = {
    source = ../../../config/lazygit;
    recursive = true;
  };
}
