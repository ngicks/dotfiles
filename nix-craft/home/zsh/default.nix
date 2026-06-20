{ ... }:
let
  compinitSnippet = ''
    # CLI completions are generated at install/upgrade time by
    # scripts/homeenv/generate-completions.sh into this dir; it must be on fpath
    # *before* compinit so the _<tool> files can be autoloaded.
    local _comp_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
    fpath=("$_comp_dir" $fpath)

    autoload -Uz compinit

    # Key the dump by zsh version + a hash of the effective fpath instead of a
    # single global ~/.zcompdump. The same $HOME is shared by multiple zsh
    # environments with different fpath values (apt/system zsh in a normal tmux
    # pane, Nix/home-manager zsh in a cmdman devenv mux, nested container
    # shells). `compinit -C` trusts whatever dump it finds regardless of which
    # fpath produced it, so a shell whose fpath lacks a function file still
    # tries to autoload it and fails with e.g.
    #   _python-argcomplete: function definition file not found
    # A per-fpath dump keeps each environment's cached metadata consistent with
    # its own completion search path. sha256sum is GNU-only; fall back so this
    # stays portable to darwin and minimal environments.
    local _fpath_hash
    if (( $+commands[sha256sum] )); then
      _fpath_hash="$(print -rl -- $fpath | sha256sum)"
    elif (( $+commands[shasum] )); then
      _fpath_hash="$(print -rl -- $fpath | shasum -a 256)"
    else
      _fpath_hash="$(print -rl -- $fpath | cksum)"
    fi
    _fpath_hash="''${_fpath_hash%% *}"
    local _zcompdump="''${ZDOTDIR:-$HOME}/.zcompdump-''${ZSH_VERSION}-''${_fpath_hash[1,12]}"
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
