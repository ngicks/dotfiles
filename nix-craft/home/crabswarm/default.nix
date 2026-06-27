{ config, ... }:
{
  xdg.configFile."crabswarm" = {
    source = ../../../config/crabswarm;
    recursive = true;
  };
}
