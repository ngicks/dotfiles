///|
async fn ssh_exec(remote : String, command : String) -> Unit raise Error {
  run_checked("ssh", [remote, command])
}

///|
async fn rsync_exec(
  remote : String,
  remote_path : String,
  local_path : String,
) -> Unit raise Error {
  run_checked("rsync", [
    "-av",
    "--partial",
    "--append-verify",
    "\{remote}:\{remote_path}",
    local_path,
  ])
}

///|
fn remote_moon_command(subargs : Array[String]) -> String {
  let args = [". ~/.zshrc", "cd ~/.dotfiles", "moon run src2 --"]
  args.append(subargs)
  args.join(" && ")
}

///|
pub async fn pull(
  remote : String,
  no_build : Bool,
  is_experimental : Bool,
) -> Unit raise Error {
  let tag = get_tag(is_experimental)
  let file_name = image_file_name(tag)
  let local_path = image_path(tag)
  let image_name = "localhost/devenv/devenv:\{tag}"

  ensure_dir(image_dir().0)

  let remote_args = ["daemon", "build", "--save", "--wait"]
  if is_experimental {
    remote_args.push("--exp")
  }
  if no_build {
    remote_args.push("--no-build")
  }
  println("running background-capable remote build on \{remote}")
  ssh_exec(remote, remote_moon_command(remote_args))

  let remote_cache_path = "~/.cache/dotfiles/devenv/image/\{file_name}"
  println("pulling \{file_name} from \{remote}")
  rsync_exec(remote, remote_cache_path, local_path)

  println("loading \{file_name} into podman")
  run_checked("podman", ["load", "-i", local_path])
  println("loaded \{image_name}")
}
