{ config, pkgs, ... }:
{
  programs.lazygit = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      os = {
        copyToClipboardCmd = "echo {{text}} | xsel -bi";
        editPreset = "nvim";
      };
      git.overrideGpg = true;
    };
  };
}
