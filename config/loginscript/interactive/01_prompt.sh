# Plain zsh prompt (replaces starship): username, host chip colored by a
# hash of the hostname, cwd, clock, and an exit-status chip on failure.
# Segments are built once at shell init; precmd only picks between the
# prebuilt variants — no per-prompt subprocess.

if [[ -z "${ZSH_NAME:-}" ]]; then
  return 0
fi

__prompt_host="$(uname -n)"

# sha256sum is GNU-only; fall back so this stays portable to darwin and
# minimal environments. cksum prints decimal, so reshape it into hex.
if (( $+commands[sha256sum] )); then
  __prompt_hash="$(printf '%s' "$__prompt_host" | sha256sum)"
elif (( $+commands[shasum] )); then
  __prompt_hash="$(printf '%s' "$__prompt_host" | shasum -a 256)"
else
  __prompt_hash="$(printf '%08x' "$(printf '%s' "$__prompt_host" | cksum | cut -d' ' -f1)")"
fi
__prompt_hash="${__prompt_hash%% *}"

if [ "${#__prompt_host}" -gt 18 ]; then
  __prompt_host="${__prompt_host[1,15]}..."
fi

__prompt_r=$((16#${__prompt_hash[1,2]}))
__prompt_g=$((16#${__prompt_hash[3,4]}))
__prompt_b=$((16#${__prompt_hash[5,6]}))
__prompt_fg="$(printf '#%02x%02x%02x' "$__prompt_r" "$__prompt_g" "$__prompt_b")"

# W3C AERT brightness formula; pick a contrasting bg for the host chip
if [ $(( (__prompt_r * 299 + __prompt_g * 587 + __prompt_b * 114) / 1000 )) -gt 128 ]; then
  __prompt_bg="#1e1c3c"
else
  __prompt_bg="#c0c0c0"
fi

# Powerline decorations from the starship format: rounded separator between
# segments and a shade block bridging username into the host chip.
__prompt_sep=$''   # U+E0B4 powerline right semicircle
__prompt_shade=$'▒' # U+2592 medium shade block
__prompt_err=$'' # error symbol (starship status.symbol)

# Each part keeps the fg/bg pair it had as a starship segment; root gets the
# old style_root color on the username chip.
__prompt_line="%K{#a3aed2}%F{#d5dee3}${__prompt_sep}%(!.%F{#8a662b}.%F{#315750}) %n%F{${__prompt_bg}}${__prompt_shade}%K{${__prompt_bg}}%F{${__prompt_fg}}[ ${__prompt_host//\%/%%} ]%K{#769ff0}%F{${__prompt_bg}}${__prompt_sep}%F{#e3e5e5} %3~ %K{#1d2230}%F{#769ff0}${__prompt_sep}%F{#a0a9cb}  %D{%H:%M:%S} %k%F{#1d2230}${__prompt_sep}%f"

# Status chip (starship status module). Aborting an empty edit line (ctrl+c)
# sets $? to 130 without running anything, so instead of %(?..) the chip is
# gated on a preexec flag: it only appears when a command actually ran.
__prompt_ok="${__prompt_line}"$'\n''%F{green}❯%f '
__prompt_fail_pre="%K{#c53b53}%F{#e3e5e5}  ${__prompt_err} "
__prompt_fail_post=" %K{#d5dee3}%F{#c53b53}${__prompt_sep}${__prompt_line}"$'\n''%F{red}❯%f '

__prompt_ran=0
__prompt_preexec() { __prompt_ran=1; }
__prompt_precmd() {
  local __prompt_code=$?
  if (( __prompt_ran && __prompt_code != 0 )); then
    PROMPT="${__prompt_fail_pre}${__prompt_code}${__prompt_fail_post}"
  else
    PROMPT="$__prompt_ok"
  fi
  __prompt_ran=0
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec __prompt_preexec
add-zsh-hook precmd __prompt_precmd
PROMPT="$__prompt_ok"

# __prompt_ok/__prompt_fail_pre/__prompt_fail_post/__prompt_ran stay: the
# precmd hook reads them on every prompt.
unset __prompt_host __prompt_hash __prompt_r __prompt_g __prompt_b __prompt_fg __prompt_bg __prompt_sep __prompt_shade __prompt_err __prompt_line
