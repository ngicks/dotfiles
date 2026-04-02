///|
fn home_dir() -> String {
  @env.get_env_var("HOME").unwrap_or(".")
}

///|
fn path_join(base : String, child : String) -> String {
  if base == "" || base == "." {
    child
  } else if base is [.., '/'] {
    base + child
  } else {
    base + "/" + child
  }
}

///|
fn cache_root() -> String {
  path_join(home_dir(), ".cache/dotfiles/devenv")
}

///|
fn image_dir() -> String {
  path_join(cache_root(), "image")
}

///|
fn daemon_dir() -> String {
  path_join(cache_root(), "daemon")
}

///|
fn daemon_info_path() -> String {
  path_join(daemon_dir(), "daemon.info")
}

///|
fn daemon_log_path() -> String {
  path_join(daemon_dir(), "daemon.log")
}

///|
fn jobs_dir() -> String {
  path_join(daemon_dir(), "jobs")
}

///|
fn job_dir(job_id : String) -> String {
  path_join(jobs_dir(), job_id)
}

///|
fn job_status_path(job_id : String) -> String {
  path_join(job_dir(job_id), "status.txt")
}

///|
fn job_log_path(job_id : String) -> String {
  path_join(job_dir(job_id), "build.log")
}

///|
pub fn image_file_name(tag : String) -> String {
  "localhost_devenv_devenv-\{tag}.tar.gz"
}

///|
pub fn image_path(tag : String) -> String {
  path_join(image_dir(), image_file_name(tag))
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
fn bool_text(value : Bool) -> String {
  if value {
    "1"
  } else {
    "0"
  }
}

///|
fn parse_bool(value : String?) -> Bool {
  match value {
    Some("1" | "true" | "yes" | "on") => true
    _ => false
  }
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
fn parse_query(path : String) -> Map[String, String] {
  let query = match path.split("?").to_array() {
    [_base, query, ..] => query
    _ => ""
  }
  let result : Map[String, String] = {}
  if query == "" {
    return result
  }
  for part in query.split("&") {
    match part.split("=").to_array() {
      [key, value] => result[key.to_string()] = value.to_string()
      [key] => result[key.to_string()] = "1"
      _ => ()
    }
  }
  result
}

///|
fn strip_query(path : String) -> String {
  match path.split("?").to_array() {
    [base, ..] => base.to_string()
    _ => path
  }
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
