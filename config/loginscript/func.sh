export_unless_container_override() {
  local var_name="$1"
  local var_value="$2"
  if [[ "${IN_CONTAINER:-}" == "1" ]] && [[ -n "${(P)var_name:-}" ]]; then
    return 0
  fi
  export "$var_name"="$var_value"
}
