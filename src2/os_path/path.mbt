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

///|
#cfg(target="windows")
pub fn user_data_dir() -> String raise Error {
  get_env_var_or_raise("LocalAppData")
}

///|
#cfg(target="darwin")
pub fn user_data_dir() -> String raise Error {
  user_home_dir() + "/Library/Application Support"
}

///|
#cfg(not(any(target="windows", target="darwin")))
pub fn user_data_dir() -> String raise Error {
  @env.get_env_var("XDG_DATA_HOME").unwrap_or(user_home_dir() + "/.local/share")
}

///|
/// Per-user runtime base directory for ephemeral state (sockets, pid/url files).
///
/// Returns `XDG_RUNTIME_DIR` when present, otherwise `/tmp`. Like the other
/// `user_*_dir` helpers this is the *base*; callers append their own app
/// namespace (e.g. `user_runtime_dir() + "/dotfiles-server"`).
pub fn user_runtime_dir() -> String {
  @env.get_env_var("XDG_RUNTIME_DIR").unwrap_or("/tmp")
}
