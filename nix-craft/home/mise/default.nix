{ config, pkgs, ... }:
{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };

  xdg.configFile."mise" = {
    source = ../../../config/mise;
    recursive = true;
  };
}
