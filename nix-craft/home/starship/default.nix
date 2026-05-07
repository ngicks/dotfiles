{ config, lib, pkgs, ... }:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      format = ''
$status[](fg:#d5dee3 bg:#a3aed2)$username''${env_var.STARSHIP_HOSTNAME}$directory[](fg:#769ff0 bg:#394260)$git_branch$git_status[](fg:#394260 bg:#212736)$nodejs$rust$golang$php[](fg:#212736 bg:#1d2230)$time[ ](fg:#1d2230)
$character
'';

      # Exit code display
      status = {
        disabled = false;
        symbol = "";
        success_symbol = "";
        format = "[[  $symbol $status ](fg:#e3e5e5 bg:#c53b53)]($style)[](fg:#c53b53 bg:#d5dee3)";
        map_symbol = true;
      };

      username = {
        show_always = true;
        style_root = "fg:#8a662b bg:#a3aed2";
        style_user = "fg:#315750 bg:#a3aed2";
        format = "[ $user]($style)";
      };

      # Hostname color string is precomputed into $_STARSHIP_HOSTNAME_CACHE
      # by .zshenv; env_var splices it in with no per-prompt subprocess.
      env_var.STARSHIP_HOSTNAME = {
        variable = "_STARSHIP_HOSTNAME_CACHE";
        format = "[$env_value](bg:#a3aed2 fg:#090c0c)";
      };

      directory = {
        style = "fg:#e3e5e5 bg:#769ff0";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          Documents = "󰈙 ";
          Downloads = " ";
          Music = " ";
          Pictures = " ";
        };
      };

      git_branch = {
        symbol = "";
        style = "bg:#394260";
        format = "[[ $symbol $branch ](fg:#769ff0 bg:#394260)]($style)";
      };

      git_status = {
        style = "bg:#394260";
        format = "[[($all_status$ahead_behind )](fg:#769ff0 bg:#394260)]($style)";
      };

      time = {
        disabled = false;
        time_format = "%T";
        style = "bg:#1d2230";
        format = "[[  $time ](fg:#a0a9cb bg:#1d2230)]($style)";
      };

      nodejs = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
      };

      rust = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
      };

      golang = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
      };

      php = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
      };
    };
  };

}
