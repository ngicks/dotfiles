{ ... }:
let
  compinitSnippet = ''
    # CLI completions are generated at install/upgrade time by
    # scripts/homeenv/generate-completions.sh into this dir; it must be on fpath
    # *before* compinit so the _<tool> files can be autoloaded.
    local _comp_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
    fpath=("$_comp_dir" $fpath)

    autoload -Uz compinit
    local _zcompdump="''${ZDOTDIR:-$HOME}/.zcompdump"
    # Load the cached dump fast. `compinit -C` never rescans fpath, so a dump
    # written before these files existed -- or by a shell that lacked _comp_dir
    # on fpath -- silently lacks them and is trusted forever. Guard against that:
    # if any generated _<tool> failed to register, rebuild the dump once. Steady
    # state stays on the fast path; a stale/poisoned dump (or a newly generated
    # completion) self-heals on the next shell.
    compinit -C -d "$_zcompdump"
    local _cf
    for _cf in "$_comp_dir"/_*(N:t); do
      if (( ! $+_comps[''${_cf#_}] )); then
        compinit -d "$_zcompdump"
        break
      fi
    done
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
      ${makeLoader "env-post"}
    '';

    profileExtra = ''
      ${makeLoader "login"}
    '';

    initContent = ''
      ${makeLoader "interactive"}
      ${interactiveEnvLoading}
    '';
  };

  xdg.configFile."loginscript" = {
    source = ../../../config/loginscript;
    recursive = true;
  };
}
