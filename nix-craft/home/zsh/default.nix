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


  cd_gitroot = pkgs.writeShellScript "cd_gitroot" ''
    GITREPO_ROOT=''${GITREPO_ROOT:-$HOME/gitrepo}
  cd ''$(FZF_DEFAULT_COMMAND="fd --type d --hidden --no-ignore '^\.git\$' ''${GITREPO_ROOT} --exec dirname {}" fzf)
  '';
in
{
  programs.zsh = {
    enable = true;
    zsh-abbr = {
      enable = true;
      abbreviations = {
        gcd = ". ${cd_gitroot}";
        homeenv-update = "~/.dotfiles/homeenv-update.sh";
        homeenv-install = "~/.dotfiles/homeenv-install.sh";
      };
    };

    initContent = ''
      bindkey -e
      bindkey '^[[1;5D' backward-word  # Ctrl+Left
      bindkey '^[[1;5C' forward-word   # Ctrl+Right

      function fzf-select-history() {
        BUFFER=''$(history -n -r 1 | fzf --query "''$LBUFFER" --reverse)
        CURSOR=''$#BUFFER
        zle reset-prompt
      }
      zle -N fzf-select-history
      bindkey '^r' fzf-select-history

      mkdir -p ''${XDG_CACHE_HOME:-$HOME/.cache}/shell
      autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
      add-zsh-hook chpwd chpwd_recent_dirs

      zstyle ':completion:*' recent-dirs-insert both
      zstyle ':chpwd:*' recent-dirs-max 500
      zstyle ':chpwd:*' recent-dirs-default true
      zstyle ':chpwd:*' recent-dirs-file "$HOME/.cache/shell/chpwd-recent-dirs"
      zstyle ':chpwd:*' recent-dirs-pushd true

      function fzf-cdr() {
        local selected_dir=''$(cdr -l | awk '{ print ''$2 }' | fzf --reverse)
        if [ -n "''$selected_dir" ]; then
          BUFFER="cd ''${selected_dir}"
          zle accept-line
        fi
        zle clear-screen
      }
      zle -N fzf-cdr
      setopt noflowcontrol
      bindkey '^q' fzf-cdr

      # Export a variable only if not in container with existing value
      export_unless_container_override() {
          local var_name="$1"
          local var_value="$2"
          if [[ "''${IN_CONTAINER:-}" == "1" ]] && [[ -n "''${!var_name:-}" ]]; then
              return 0
          fi
          export "$var_name"="$var_value"
      }

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

  xdg.configFile."loginscript" = {
    source = ../../../config/loginscript;
    recursive = true;
  };
}
