{ config, pkgs, ... }:
{
  programs.tmux = {
    enable = true;
  };

  xdg.configFile."tmux" = {
    source = ../../../config/tmux;
    recursive = true;
  };
}
