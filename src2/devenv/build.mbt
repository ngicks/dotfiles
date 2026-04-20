///|
/// repository name for images
pub let repository = "localhost/devenv/devenv"

///|
pub fn repo_tag(tag : String) -> String {
  repository + ":" + tag
}

///|
pub async fn git_tag() -> String raise Error {
  let (exit_code, stdout) = @process.collect_stdout("git", [
    "describe", "--tags", "--abbrev=0",
  ])
  if exit_code != 0 {
    raise Failure::Failure("git describe --tags --abbrev=0 failed")
  }
  let tag = stdout.text().trim()
  if tag.has_prefix("v") {
    tag[1:].to_string()
  } else {
    tag.to_string()
  }
}

///|
pub async fn get_tag(is_experimental : Bool) -> String raise Error {
  let ver = git_tag()
  if is_experimental {
    ver + "-exp1"
  } else {
    ver
  }
}

///|
pub async fn is_already_built(ver : String) -> Bool {
  let exit_code = @process.run("podman", ["image", "inspect", repo_tag(ver)])
  exit_code == 0
}

///|
pub async fn build_ver(
  ver : String,
  is_experimental : Bool,
) -> Unit raise Error {
  let git_tag_val = if is_experimental { "exp" } else { ver }
  let args : Array[String] = [
    "buildx",
    "build",
    ".",
    "--build-arg",
    "GIT_TAG=" + git_tag_val,
    "-f",
    "./devenv/Containerfile",
    "-t",
    repo_tag(ver),
    "--no-cache",
  ]
  // proxy env vars
  match @env.get_env_var("HTTP_PROXY") {
    Some(_) => {
      let proxy_vars : Array[String] = [
        "HTTP_PROXY", "HTTPS_PROXY", "NO_PROXY", "http_proxy", "https_proxy", "no_proxy",
      ]
      for v in proxy_vars {
        let val = @env.get_env_var(v).unwrap_or("")
        args..push("--build-arg").push(v + "=" + val)
      }
    }
    None => ()
  }
  // SSL cert secret
  args..push("--secret").push("id=cert,src=" + ca_file_path())
  let exit_code = @process.run("podman", args)
  if exit_code != 0 {
    raise Failure::Failure("build failed")
  }
}

///|
pub async fn build(is_experimental : Bool) -> Unit raise Error {
  let ver = get_tag(is_experimental)
  println("building " + repo_tag(ver))
  if is_already_built(ver) {
    println("already built")
    return
  }
  build_ver(ver, is_experimental)
}
