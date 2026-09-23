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
    # its own completion search path. The key is a 32-bit FNV-1a over the
    # joined fpath, computed in shell arithmetic: it only has to tell
    # environments apart, and this avoids forking a hash utility on every
    # shell start.
    local _fpath_str="''${(j.:.)fpath}" _fpath_c _fpath_hash
    local -i _fpath_i _fpath_h=2166136261
    for (( _fpath_i = 1; _fpath_i <= ''${#_fpath_str}; _fpath_i++ )); do
      _fpath_c="''${_fpath_str[_fpath_i]}"
      (( _fpath_h = ((_fpath_h ^ #_fpath_c) * 16777619) & 0xffffffff ))
    done
    printf -v _fpath_hash '%08x' "$_fpath_h"
    unset _fpath_str _fpath_c _fpath_i _fpath_h
    local _zcompdump="''${ZDOTDIR:-$HOME}/.zcompdump-''${ZSH_VERSION}-''${_fpath_hash}"
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
    # The dump is the largest file zsh reads at startup; compinit sources it
    # with `.`, which prefers a sibling .zwc that is not older than the dump.
    # Compile it in the background so the current shell never waits, and only
    # when missing or stale (a rebuilt dump outdates the old .zwc by mtime).
    if [[ -f "$_zcompdump" && ( ! -f "$_zcompdump.zwc" || "$_zcompdump" -nt "$_zcompdump.zwc" ) ]]; then
      { zcompile "$_zcompdump" } 2>/dev/null &!
    fi
  '';

  # Written to run under bash as well as zsh, so the same loader can be
  # reused from bash-side scripts. An unmatched glob stays literal in bash
  # and would raise "no matches found" in zsh, so the zsh branch turns on
  # null_glob for the function's scope and the -f test covers bash.
  envLoading = ''
    __load_env_dir() {
      local env_dir="$1" f
      [ -d "$env_dir" ] || return 0
      if [ -n "''${ZSH_VERSION:-}" ]; then
        setopt local_options null_glob
      fi
      for f in "$env_dir"/*.env; do
        [ -f "$f" ] || continue
        set -a
        . "$f"
        set +a
      done
      for f in "$env_dir"/*.sh; do
        [ -f "$f" ] || continue
        . "$f"
      done
    }
    __load_env_dir "''${XDG_CONFIG_HOME:-$HOME/.config}/env"
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

  loadEnv = ''
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
in
{
  programs.zsh = {
    enable = true;
    completionInit = compinitSnippet;

    envExtra = ''
      # Login shells load env in .zprofile instead: home-manager's session vars
      # (nix-profile PATH, where mise lives) are skipped in .zshenv for login
      # shells and only set in .zprofile, so loading here would run 00_mise.sh
      # before mise is on PATH. Non-login shells (ssh host "cmd", zsh -c) never
      # read .zprofile, so they must load here.
      if [[ ! -o login ]]; then
        ${loadEnv}
      fi
    '';

    profileExtra = ''
      ${loadEnv}
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
