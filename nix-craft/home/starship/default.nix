{ config, lib, pkgs, ... }:
let
  # Hostname color script: computes color from hostname hash
  hostnameColorScript = pkgs.writeShellScript "starship-hostname-color" ''
    hostname=$(uname -n)
    hash=$(echo -n "$hostname" | sha256sum | cut -c1-6)

    if [ "''${#hostname}" -gt 18 ]; then
        hostname="$(echo $hostname | cut -c1-15)..."
    fi

    r=$((16#''${hash:0:2}))
    g=$((16#''${hash:2:2}))
    b=$((16#''${hash:4:2}))

    # W3C AERT brightness formula
    brightness=$(( (r * 299 + g * 587 + b * 114) / 1000 ))

    # Background based on hostname color brightness (inverted)
    if [ $brightness -gt 128 ]; then
      bg="30;28;60"      # dark background for bright hostname color
    else
      bg="192;192;192"   # light background for dark hostname color
    fi

    # Output: "[ hostname ]" in computed color with inverted bg
    printf '\033[48;2;%sm\033[38;2;%d;%d;%dm[ %s ]\033[48;2;118;159;240m\033[38;2;%sm\033[0m' "$bg" "$r" "$g" "$b" "$hostname" "$bg"
  '';
in {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      format = ''
$status[](fg:#d5dee3 bg:#a3aed2)$username''${custom.hostname}$directory[](fg:#769ff0 bg:#394260)$git_branch$git_status[](fg:#394260 bg:#212736)$nodejs$rust$golang$php[](fg:#212736 bg:#1d2230)$time[ ](fg:#1d2230)
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
        format = "[ $user:]($style)";
      };

      # Custom hostname: [ hostname ] with computed colors
      custom.hostname = {
        command = "${hostnameColorScript}";
        when = true;
        format = "[$output](bg:#a3aed2 fg:#090c0c)";
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
