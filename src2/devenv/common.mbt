///|
fn home_dir() -> @path.Path {
  @path.Path(@env.get_env_var("HOME").unwrap_or("."))
}

///|
fn cache_root() -> @path.Path {
  home_dir().join(@path.Path(".cache/dotfiles/devenv"))
}

///|
fn image_dir() -> @path.Path {
  cache_root().join(@path.Path("image"))
}

///|
fn daemon_dir() -> @path.Path {
  cache_root().join(@path.Path("daemon"))
}

///|
fn daemon_info_path() -> String {
  daemon_dir().join(@path.Path("daemon.info")).0
}

///|
fn daemon_log_path() -> String {
  daemon_dir().join(@path.Path("daemon.log")).0
}

///|
fn jobs_dir() -> @path.Path {
  daemon_dir().join(@path.Path("jobs"))
}

///|
fn job_dir(job_id : String) -> @path.Path {
  jobs_dir().join(@path.Path(job_id))
}

///|
fn job_status_path(job_id : String) -> String {
  job_dir(job_id).join(@path.Path("status.txt")).0
}

///|
fn job_log_path(job_id : String) -> String {
  job_dir(job_id).join(@path.Path("build.log")).0
}

///|
pub fn image_file_name(tag : String) -> String {
  "localhost_devenv_devenv-\{tag}.tar.gz"
}

///|
pub fn image_path(tag : String) -> String {
  image_dir().join(@path.Path(image_file_name(tag))).0
}

///|
fn parse_kv(text : String) -> Map[String, String] {
  let result : Map[String, String] = {}
  for line in text.split("\n") {
    let line = line.trim(char_set="\r\n ")
    if line == "" {
      break
    }
    match line.split("=").to_array() {
      [key, .. rest] => result[key.to_string()] = rest.join("=")
      _ => ()
    }
  }
  result
}

///|
fn encode_kv(values : Map[String, String]) -> String {
  let buf = StringBuilder::new()
  for key, value in values {
    buf.write_string(key)
    buf.write_string("=")
    buf.write_string(value)
    buf.write_string("\n")
  }
  buf.write_string("\n")
  buf.to_string()
}

///|
async fn ensure_dir(path : String) -> Unit raise Error {
  @fs.mkdir(path, permission=0o755, recursive=true)
}

///|
async fn read_text_if_exists(path : String) -> String? raise Error {
  if @fs.exists(path) {
    Some(@fs.read_file(path).text())
  } else {
    None
  }
}

///|
async fn write_text(path : String, text : String) -> Unit raise Error {
  @fs.write_file(path, text, create=0o644, truncate=true)
}

///|
async fn run_checked(
  cmd : String,
  args : Array[String],
  cwd? : String,
  extra_env? : Map[String, String],
) -> Unit raise Error {
  let cwd : StringView? = cwd.map(fn(s) { s[:] })
  let exit_code = @process.run(cmd, args, extra_env?, cwd?)
  if exit_code != 0 {
    raise Failure::Failure("\{cmd} failed with exit code \{exit_code}")
  }
}

///|
fn get_current_dir() -> String raise Error {
  match @env.current_dir() {
    Some(cwd) => cwd
    None => raise Failure::Failure("current working directory is unavailable")
  }
}

///|
fn parse_daemon_info(text : String) -> (Int, Int)? raise Error {
  let values = parse_kv(text)
  guard values.get("pid") is Some(pid_text)
  guard values.get("port") is Some(port_text)
  Some((@string.parse_int(pid_text), @string.parse_int(port_text)))
}
