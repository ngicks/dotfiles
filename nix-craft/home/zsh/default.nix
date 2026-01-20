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

  zshSetup = ''
    export ZSH="$HOME/.oh-my-zsh"
    ZSH_THEME="obraun"
    plugins=(git)
    source $ZSH/oh-my-zsh.sh
  '';

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
      # 1. Zsh setup
      ${zshSetup}

      # 2-1. Load config
      ${initScriptContent}

      # 2-2: Load config from ~/.config/loginscript/
      ${loginscriptLoading}

      # 3. Load environment-specific config (~/.config/env/*)
      ${envLoading}

      # 4. Daily update check
      ${dailyUpdateCheck}
    '';
  };

  xdg.configFile."loginscript" = {
    source = ../../../config/loginscript;
    recursive = true;
  };
}
