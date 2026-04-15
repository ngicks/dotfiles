# Safe hook append with deduplication for bash-preexec style arrays
# Usage: safe_hook_append <array_name> <function_name>
safe_hook_append() {
    local array_name="$1"
    local func_name="$2"

    if [[ -n "${ZSH_NAME:-}" ]]; then
        # zsh: use (P) flag for indirect expansion
        # [(I)pattern] returns index of pattern in array, 0 if not found
        # :-0 handles case where array does not exist yet
        if (( ${${(P)array_name}[(I)$func_name]:-0} == 0 )); then
            eval "${array_name}+=(\"\$func_name\")"
        fi
    else
        # bash 4.3+: use nameref
        local -n arr_ref="$array_name"
        local item
        for item in "${arr_ref[@]}"; do
            [[ "$item" == "$func_name" ]] && return 0
        done
        arr_ref+=("$func_name")
    fi
}

# Convenience: register precmd+preexec pair
safe_hook_pair() {
    [[ -n "$1" ]] && safe_hook_append precmd_functions "$1"
    [[ -n "$2" ]] && safe_hook_append preexec_functions "$2"
}
