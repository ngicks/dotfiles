///|
/// Directory holding the daily-update markers.
///
/// Mirrors the login script's `${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles` exactly
/// (not the platform cache dir), so both sides agree on every OS.
fn marker_dir() -> String raise Error {
  let cache = @env.get_env_var("XDG_CACHE_HOME").unwrap_or(
    @os_path.join(@os_path.user_home_dir(), ".cache"),
  )
  @os_path.join(cache, "dotfiles")
}

///|
/// Stamp the interval marker (`.update_daily`) so the login script defers the
/// next run.
///
/// Only called once every task has succeeded; on failure the marker is left
/// untouched so the next login retries.
async fn touch_marker() -> Unit raise Error {
  let dir = marker_dir()
  if !@fs.exists(dir) {
    @fs.mkdir(dir, permission=0o755, recursive=true)
  }
  @fs.write_file(
    @os_path.join(dir, ".update_daily"),
    "",
    create_mode=@fs.CreateMode::CreateOrTruncate,
    permission=0o644,
  )
}
