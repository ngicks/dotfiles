# Populate _STARSHIP_HOSTNAME_CACHE consumed by env_var.STARSHIP_HOSTNAME in
# starship. Layered cache: inherited env -> file under XDG_RUNTIME_DIR -> compute.

if [ -z "${_STARSHIP_HOSTNAME_CACHE:-}" ]; then
  __starship_dir="${XDG_RUNTIME_DIR:-/tmp}/starship-cache-$(id -u)"
  __starship_file="$__starship_dir/host-color"

  if [ -r "$__starship_file" ]; then
    export _STARSHIP_HOSTNAME_CACHE="$(cat "$__starship_file")"
  else
    __starship_host=$(uname -n)
    __starship_hash=$(printf '%s' "$__starship_host" | sha256sum | cut -c1-6)

    if [ "${#__starship_host}" -gt 18 ]; then
      __starship_host="${__starship_host:0:15}..."
    fi

    __starship_r=$((16#${__starship_hash:0:2}))
    __starship_g=$((16#${__starship_hash:2:2}))
    __starship_b=$((16#${__starship_hash:4:2}))

    # W3C AERT brightness formula; pick a contrasting bg for the host color block
    if [ $(( (__starship_r * 299 + __starship_g * 587 + __starship_b * 114) / 1000 )) -gt 128 ]; then
      __starship_bg="30;28;60"
    else
      __starship_bg="192;192;192"
    fi

    # \342\226\222 = U+2592 (medium shade block), \356\202\264 = U+E0B4 (powerline arrow)
    __starship_out=$(printf '\033[48;2;163;174;210m\033[38;2;%sm\342\226\222\033[48;2;%sm\033[38;2;%d;%d;%dm[ %s ]\033[48;2;118;159;240m\033[38;2;%sm\356\202\264\033[0m' \
      "$__starship_bg" "$__starship_bg" "$__starship_r" "$__starship_g" "$__starship_b" "$__starship_host" "$__starship_bg")

    mkdir -p "$__starship_dir" 2>/dev/null && \
      printf '%s' "$__starship_out" > "$__starship_file" 2>/dev/null

    export _STARSHIP_HOSTNAME_CACHE="$__starship_out"

    unset __starship_host __starship_hash __starship_r __starship_g __starship_b __starship_bg __starship_out
  fi

  unset __starship_dir __starship_file
fi
