{ config, lib, ... }:
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
        [░▒▓](#a3aed2)[  ](bg:#a3aed2 fg:#090c0c)[](bg:#769ff0 fg:#a3aed2)$directory[](fg:#769ff0 bg:#394260)$git_branch$git_status[](fg:#394260 bg:#212736)$nodejs$rust$golang$php[](fg:#212736 bg:#1d2230)$time[ ](fg:#1d2230)
        $character'';

      directory = {
        style = "fg:#e3e5e5 bg:#769ff0";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          Documents = "󰈙 ";
          Downloads = " ";
          Music = " ";
          Pictures = " ";
        };
      };

      git_branch = {
        symbol = "";
        style = "bg:#394260";
        format = "[[ $symbol $branch ](fg:#769ff0 bg:#394260)]($style)";
      };

      git_status = {
        style = "bg:#394260";
        format = "[[($all_status$ahead_behind )](fg:#769ff0 bg:#394260)]($style)";
      };

      nodejs = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
      };

      rust = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
      };

      golang = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
      };

      php = {
        symbol = "";
        style = "bg:#212736";
        format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
      };

      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:#1d2230";
        format = "[[  $time ](fg:#a0a9cb bg:#1d2230)]($style)";
      };
    };
  };

  xdg.configFile."loginscript" = {
    source = ../../../config/loginscript;
    recursive = true;
  };
}
