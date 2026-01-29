{ config, pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    extraLuaPackages = ps: [ ps.magick ];
    extraPackages = with pkgs; [ ripgrep fd xsel xclip imagemagick ];
  };

  xdg.configFile."nvim" = {
    source = ../../../config/nvim;
    recursive = true;
  };
}
