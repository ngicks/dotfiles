{ config, pkgs, ... }:
{
  programs.mise = {
    enable = true;
    # loginscript/env/00_mise.sh already runs `mise activate` in the env
    # stage, for non-interactive shells too. The module's own activation
    # would run it a second time at the end of .zshrc, costing another
    # `mise` and `hook-env` fork per shell.
    enableZshIntegration = false;
  };

  xdg.configFile."mise" = {
    source = ../../../config/mise;
    recursive = true;
  };
}
