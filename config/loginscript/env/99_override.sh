# Overcome `mise activate` hooks
_prepend_override_path() {
  local dir="$HOME/.local/bin/override"
  case ":${PATH}:" in
    "${dir}:"*) return 0 ;;  # already first: nothing to do
  esac
  # Strip any existing occurrence, then prepend so override always wins.
  local p=":${PATH}:"
  p="${p//:${dir}:/:}"
  p="${p#:}"
  p="${p%:}"
  if [ -n "$p" ]; then
    export PATH="${dir}:${p}"
  else
    export PATH="${dir}"
  fi
}
_prepend_override_path

if [ -n "${ZSH_VERSION:-}" ]; then
  autoload -Uz add-zsh-hook 2>/dev/null
  add-zsh-hook -d precmd _prepend_override_path 2>/dev/null
  add-zsh-hook precmd _prepend_override_path 2>/dev/null
elif [ -n "${BASH_VERSION:-}" ]; then
  case "${PROMPT_COMMAND:-}" in
    *_prepend_override_path*) ;;
    *)
      if [ -n "${PROMPT_COMMAND:-}" ]; then
        PROMPT_COMMAND="${PROMPT_COMMAND}"$'\n'"_prepend_override_path"
      else
        PROMPT_COMMAND="_prepend_override_path"
      fi
      ;;
  esac
fi
