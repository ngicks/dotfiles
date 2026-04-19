///|
fn get_env_var_or_raise(name : String) -> String raise Error {
  match @env.get_env_var(name) {
    Some(value) => value
    None => raise Failure::Failure("env var \{name} is not defined")
  }
}

///|
#cfg(target="windows")
pub fn user_home_dir() -> String raise Error {
  get_env_var_or_raise("USERPROFILE")
}

///|
#cfg(not(target="windows"))
pub fn user_home_dir() -> String raise Error {
  get_env_var_or_raise("HOME")
}

///|
#cfg(target="windows")
pub fn user_config_dir() -> String raise Error {
  get_env_var_or_raise("AppData")
}

///|
#cfg(target="darwin")
pub fn user_config_dir() -> String raise Error {
  user_home_dir() + "/Library/Application Support"
}

///|
#cfg(not(any(target="windows", target="darwin")))
pub fn user_config_dir() -> String raise Error {
  @env.get_env_var("XDG_CONFIG_HOME").unwrap_or(user_home_dir() + "/.config")
}

///|
#cfg(target="windows")
pub fn user_cache_dir() -> String raise Error {
  get_env_var_or_raise("LocalAppData")
}

///|
#cfg(target="darwin")
pub fn user_cache_dir() -> String raise Error {
  user_home_dir() + "/Library/Caches"
}

///|
#cfg(not(any(target="windows", target="darwin")))
pub fn user_cache_dir() -> String raise Error {
  @env.get_env_var("XDG_CACHE_HOME").unwrap_or(user_home_dir() + "/.cache")
}
