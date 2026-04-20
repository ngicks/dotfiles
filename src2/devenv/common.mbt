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
