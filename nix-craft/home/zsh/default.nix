{ ... }:
let
  compinitSnippet = ''
    autoload -U compinit
    if [[ -n "''${ZDOTDIR:-}" ]]; then
      compinit -C -d "''${ZDOTDIR}/.zcompdump"
    else
      compinit -C -d "$HOME/.zcompdump"
    fi
  '';

  envLoading = ''
    local env_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/env"
    if [[ -d "$env_dir" ]]; then
      if ls "$env_dir"/ | grep -e '.*\.env' > /dev/null 2>&1; then
        for f in "$env_dir"/*.env; do
          set -a
          . "$f"
          set +a
        done
      fi

      if ls "$env_dir"/ | grep -e '.*\.sh' > /dev/null 2>&1; then
        for f in "$env_dir"/*.sh; do
          . "$f"
        done
      fi
    fi
  '';

  interactiveEnvLoading = ''
    local interactive_env_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/env/interactive"
    if [[ -d "$interactive_env_dir" ]]; then
      for f in "$interactive_env_dir"/*.sh; do
        [[ -f "$f" ]] && . "$f"
      done
    fi
  '';

  makeLoader = dir: ''
    local loginscript_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/loginscript/${dir}"
    if [[ -d "$loginscript_dir" ]]; then
      for f in "$loginscript_dir"/*.sh; do
        [[ -f "$f" ]] && . "$f"
      done
    fi
  '';
in
{
  programs.zsh = {
    enable = true;
    completionInit = compinitSnippet;
    zsh-abbr = {
      enable = true;
      abbreviations = {
        homeup = "~/.dotfiles/homeenv-upgrade.sh";
        homesync = "~/.dotfiles/homeenv-install.sh";
      };
    };

    envExtra = ''
      # this script may change ''${XDG_CONFIG_HOME}
      if [[ -f "$HOME/.config/env/.first_rc" ]]; then
        . "$HOME/.config/env/.first_rc"
      fi

      local loginscript_func="''${XDG_CONFIG_HOME:-$HOME/.config}/loginscript/func.sh"
      if [[ -f "$loginscript_func" ]]; then
        . "$loginscript_func"
      fi

      ${makeLoader "env"}
      ${envLoading}
    '';

    profileExtra = ''
      ${makeLoader "login"}
    '';

    initExtra = ''
      ${makeLoader "interactive"}
      ${interactiveEnvLoading}
    '';
  };

  xdg.configFile."loginscript" = {
    source = ../../../config/loginscript;
    recursive = true;
  };
}
