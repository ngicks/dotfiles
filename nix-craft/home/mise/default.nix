{ config, pkgs, ... }:
{
  programs.mise = {
    enable = true;
  };

  xdg.configFile."mise" = {
    source = ../../../config/mise;
    recursive = true;
  };
}
