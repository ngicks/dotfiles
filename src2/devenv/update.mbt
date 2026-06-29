///|
/// The current `HEAD` commit of the repository at `repo_dir`.
pub async fn git_head(repo_dir : String) -> String raise Error {
  let (exit_code, stdout) = @process.collect_stdout(
    "git",
    ["rev-parse", "HEAD"],
    cwd=repo_dir,
  )
  if exit_code != 0 {
    raise Failure::Failure("git rev-parse HEAD failed in \{repo_dir}")
  }
  stdout.text().trim().to_owned()
}

///|
/// Directory holding the daily-update marker.
///
/// Mirrors the login script's `${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles` exactly
/// (not the platform cache dir), so both sides agree on every OS.
fn daily_marker_dir() -> String raise Error {
  let cache = @env.get_env_var("XDG_CACHE_HOME").unwrap_or(
    @os_path.user_home_dir() + "/.cache",
  )
  cache + "/dotfiles"
}

///|
/// Stamp the daily-update marker (`.update_daily`) with the current time.
async fn touch_daily_marker() -> Unit raise Error {
  let dir = daily_marker_dir()
  @fs.mkdir(dir, permission=0o755, recursive=true)
  @fs.write_file(
    dir + "/.update_daily",
    "",
    create_mode=@fs.CreateMode::CreateOrTruncate,
    permission=0o644,
  )
}

///|
/// Fast-forward the repository at `repo_dir` and rebuild the image if it moved.
///
/// Run from the zsh login script: pull, rebuild only when `HEAD` actually
/// advanced (so repeated runs are cheap no-ops), then stamp the interval marker.
/// On failure the marker is left untouched, so the next login retries.
pub async fn update_daily(repo_dir : String) -> Unit raise Error {
  let before = git_head(repo_dir)
  println("updating \{repo_dir}")
  run_checked("git", ["pull", "--ff-only"], cwd=repo_dir)
  let after = git_head(repo_dir)
  if before == after {
    println("already up to date at \{after}")
  } else {
    println("updated \{before} -> \{after}, rebuilding devenv image")
    build(repo_dir, false)
  }
  touch_daily_marker()
}
