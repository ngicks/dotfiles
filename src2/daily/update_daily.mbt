///|
/// Run the daily update for the checkout at `repo_dir`, then stamp the marker.
///
/// Equivalent to `deno task update:daily`: it runs the extensible `tasks()` list
/// (git pull + host-side config sync) and, only when every task succeeds, stamps
/// the `.update_daily` interval marker. If any task fails the marker is left
/// untouched so the next login retries.
///
/// The interval / `.no_update_daily` / force gating lives in the zsh login
/// script (`dotfiles_should_update`); this command just does the work and the
/// stamping.
pub async fn update_daily(repo_dir : String) -> Unit raise Error {
  println("running daily update in \{repo_dir}")
  run_tasks(repo_dir, tasks())
  touch_marker()
  println("daily update done")
}
