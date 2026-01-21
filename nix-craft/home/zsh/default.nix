{ config, lib, pkgs, ... }:
let
  loginscriptPath = ./loginscript;

  # Part 2: Read all .sh files from loginscript/
  loginscriptFiles = builtins.filter
    (name: lib.hasSuffix ".sh" name)
    (builtins.attrNames (builtins.readDir loginscriptPath));

  sortedFiles = builtins.sort (a: b: a < b) loginscriptFiles;

  initScriptContent = lib.concatMapStringsSep "\n"
    (file: builtins.readFile "${loginscriptPath}/${file}")
    sortedFiles;

  loginscriptLoading = ''
    if [[ -d "$HOME/.config/loginscript" ]]; then
      for f in $HOME/.config/loginscript/*.sh; do
        [[ -f "$f" ]] && . "$f"
      done
    fi
  '';

  envLoading = ''
    if [[ -d "$HOME/.config/env" ]]; then
      if ls $HOME/.config/env/ | grep -e '.*\.env' > /dev/null 2>&1; then
        for f in $HOME/.config/env/*.env; do
          set -a
          . $f
          set +a
        done
      fi

      if ls $HOME/.config/env/ | grep -e '.*\.sh' > /dev/null 2>&1; then
        for f in $HOME/.config/env/*.sh; do
          . $f
        done
      fi
    fi
  '';

  dailyUpdateCheck = ''
    # Run daily update check
    if command -v dotfiles_should_update >/dev/null 2>&1; then
      if dotfiles_should_update; then
        pushd $HOME/.dotfiles > /dev/null
        deno task update:daily > /dev/null
        popd > /dev/null
      else
        echo "update deferred"
        echo "If you want update to happen again immediately, remove $HOME/.cache/dotfiles/.update_daily"
        echo ""
        echo "next update occurrs after $(dotfiles_next_update_time)"
      fi
    else
      # Fallback if function not defined
      pushd $HOME/.dotfiles > /dev/null
      deno task update:daily > /dev/null
      popd > /dev/null
    fi
  '';

  # Hostname color script: computes color from hostname hash
  hostnameColorScript = pkgs.writeShellScript "starship-hostname-color" ''
    hostname=$(hostname -s)
    hash=$(echo -n "$hostname" | sha256sum | cut -c1-6)

    r=$((16#''${hash:0:2}))
    g=$((16#''${hash:2:2}))
    b=$((16#''${hash:4:2}))

    # W3C AERT brightness formula
    brightness=$(( (r * 299 + g * 587 + b * 114) / 1000 ))

    # Background based on hostname color brightness (inverted)
    if [ $brightness -gt 128 ]; then
      bg="16;16;16"      # dark background for bright hostname color
    else
      bg="192;192;192"   # light background for dark hostname color
    fi

    # Output: "[ hostname ]" in computed color with inverted bg
    printf '\033[48;2;%sm\033[38;2;%d;%d;%dm[ %s ]\033[48;2;118;159;240m\033[38;2;%sm\033[0m' "$bg" "$r" "$g" "$b" "$hostname" "$bg"
  '';
in
{
  programs.zsh = {
    enable = true;
    zsh-abbr = {
      enable = true;
      abbreviations = {
        gcd = "cd $(dirname $(fzf --walker-root=$HOME/gitrepo))";
        homeenv-update = "~/.dotfiles/homeenv-update.sh";
        homeenv-install = "~/.dotfiles/homeenv-install.sh";
      };
    };

    initContent = ''
      # 1. Load config
      ${initScriptContent}

      # 2. Load config from ~/.config/loginscript/
      ${loginscriptLoading}

      # 3. Load environment-specific config (~/.config/env/*)
      ${envLoading}

      # 4. Daily update check
      ${dailyUpdateCheck}
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      format = ''
$status[](fg:#d5dee3 bg:#a3aed2)$username''${custom.hostname}$directory[](fg:#769ff0 bg:#394260)$git_branch$git_status[](fg:#394260 bg:#212736)$nodejs$rust$golang$php[](fg:#212736 bg:#1d2230)$time[ ](fg:#1d2230)
$character
'';

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

      time = {
        disabled = false;
        time_format = "%T";
        style = "bg:#1d2230";
        format = "[[  $time ](fg:#a0a9cb bg:#1d2230)]($style)";
      };

      username = {
        show_always = true;
        style_root = "fg:#a36d15 bg:#a3aed2";
        style_user = "fg:#315750 bg:#a3aed2";
        format = "[ $user:]($style)";
      };

      # Custom hostname: [ hostname ] with computed colors
      custom.hostname = {
        command = "${hostnameColorScript}";
        when = true;
        format = "[$output](bg:#a3aed2 fg:#090c0c)";
      };

      # Exit code display
      status = {
        disabled = false;
        symbol = "";
        success_symbol = "";
        format = "[[  $symbol $status ](fg:#e3e5e5 bg:#c53b53)]($style)[](fg:#c53b53 bg:#d5dee3)";
        map_symbol = true;
      };
    };
  };

  xdg.configFile."loginscript" = {
    source = ../../../config/loginscript;
    recursive = true;
  };
}
