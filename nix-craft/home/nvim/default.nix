{ config, pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    extraPackages = with pkgs; [ ripgrep fd xsel xclip ];
  };

  xdg.configFile."nvim" = {
    source = ../../../config/nvim;
    recursive = true;
  };
}
