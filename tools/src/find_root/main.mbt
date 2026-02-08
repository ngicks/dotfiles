///|
/// find-root: Find project root by walking parent directories.
///
/// This is a helper that computes the parent directory traversal path.
/// The actual filesystem marker checking is done by the wrapper shell script,
/// since moonrun's WASI does not support directory stat operations.
///
/// Usage: find-root [start-path]
/// Prints each parent directory (from start to /) to stdout, one per line.
/// The wrapper script checks each for marker files (.git, .claude, AGENTS.md).
fn main {
  let args = @env.args()
  let start = if args.length() > 1 { args[1] } else {
    match @env.current_dir() {
      Some(cwd) => cwd
      None => {
        println("error: cannot determine current directory")
        return
      }
    }
  }
  // Print the start directory and all parents
  let mut dir : String? = Some(start)
  while true {
    match dir {
      Some(d) => {
        println(d)
        dir = @lib.parent_dir(d)
      }
      None => break
    }
  }
}
