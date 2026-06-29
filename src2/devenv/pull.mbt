///|
/// Run `command` on `remote` over SSH.
async fn ssh_exec(remote : String, command : String) -> Unit raise Error {
  run_checked("ssh", [remote, command])
}

///|
/// Build the shell command that drives the dotfiles CLI on a remote host.
///
/// Sources the login shell so `moon`/`mise` are on PATH, enters the checkout,
/// and runs the standalone build through `moon run`.
fn remote_build_command(subargs : Array[String]) -> String {
  let parts = [
    ". ~/.zshrc",
    "cd ~/.dotfiles",
    "moon run src2 -- " + subargs.join(" "),
  ]
  parts.join(" && ")
}

///|
/// Build the devenv image on `remote` and copy it into local container storage.
///
/// The remote build is triggered over SSH, then `oci-image-copy` streams the
/// resulting image directly between the two hosts' container stores over SSH
/// (skopeo + sftp), avoiding any intermediate tarball.
pub async fn pull(
  repo_dir : String,
  remote : String,
  is_experimental : Bool,
) -> Unit raise Error {
  let tag = get_tag(repo_dir, is_experimental)
  let image = repo_tag(tag)
  let build_args = ["standalone", "devenv", "build"]
  if is_experimental {
    build_args.push("--exp")
  }
  println("triggering remote build on \{remote}")
  ssh_exec(remote, remote_build_command(build_args))
  println("copying \{image} from \{remote} via oci-image-copy")
  run_checked("oci-image-copy", [
    "pull",
    image,
    "--remote",
    "ssh://" + remote,
    "--local",
    "containers-storage:",
  ])
  println("pulled \{image}")
}
