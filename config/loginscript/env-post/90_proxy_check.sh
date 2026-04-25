if [[ -n "${HTTP_PROXY:-}${HTTPS_PROXY:-}" && -n "${XDG_RUNTIME_DIR:-}" ]]; then
  __proxy_check_flag="${XDG_RUNTIME_DIR}/proxy_check_done"
  if [[ -f "$__proxy_check_flag" ]]; then
    read __proxy_check_result < "$__proxy_check_flag"
  else
    __proxy_check_url="${HTTP_PROXY:-${HTTPS_PROXY:-${http_proxy:-${https_proxy:-}}}}"
    if curl -sI -m 10 -o /dev/null --noproxy '*' "$__proxy_check_url" 2>/dev/null; then
      __proxy_check_result=1
    else
      __proxy_check_result=0
    fi
    printf '%s\n' "$__proxy_check_result" > "$__proxy_check_flag" 2>/dev/null
    unset __proxy_check_url
  fi
  [[ "$__proxy_check_result" == "0" ]] && no_proxy
  unset __proxy_check_flag __proxy_check_result
fi
