{ ... }:
let
  compinitSnippet = ''
    # Lazily-autoloaded CLI completions generated at install/upgrade time by
    # scripts/homeenv/generate-completions.sh. Must be prepended to fpath
    # *before* compinit so the _<tool> files get picked up.
    local _comp_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
    fpath=("$_comp_dir" $fpath)

    autoload -Uz compinit
    local _zcompdump="''${ZDOTDIR:-$HOME}/.zcompdump"
    # `compinit -C` trusts the cached .zcompdump and never rescans fpath, so a
    # freshly generated _<tool> file stays invisible until the dump is rebuilt.
    # Rebuild fully when the dump is missing or older than the newest completion
    # file (zsh `om[1]` = most-recently-modified); else take the fast cached path.
    local _newest_comp=( "$_comp_dir"/_*(Nom[1]) )
    if [[ ! -f "$_zcompdump" || ( -n "$_newest_comp" && "$_newest_comp" -nt "$_zcompdump" ) ]]; then
      compinit -d "$_zcompdump"
    else
      compinit -C -d "$_zcompdump"
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
