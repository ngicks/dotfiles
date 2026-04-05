///|
priv struct DaemonState {
  cwd : String
  mut next_job_id : Int
}

///|
fn info_text(pid : Int, port : Int) -> String {
  encode_kv({ "pid": pid.to_string(), "port": port.to_string() })
}

///|
fn status_text(
  job_id : String,
  tag : String,
  state : String,
  save : Bool,
  no_build : Bool,
  is_experimental : Bool,
  artifact? : String,
  exit_code? : String,
  error? : String,
) -> String {
  let values : Map[String, String] = {
    "job_id": job_id,
    "tag": tag,
    "state": state,
    "save": bool_text(save),
    "no_build": bool_text(no_build),
    "exp": bool_text(is_experimental),
  }
  if artifact is Some(artifact) {
    values["artifact"] = artifact
  }
  if exit_code is Some(exit_code) {
    values["exit_code"] = exit_code
  }
  if error is Some(error) {
    values["error"] = error
  }
  encode_kv(values)
}

///|
async fn read_status(job_id : String) -> String raise Error {
  read_text_if_exists(job_status_path(job_id)).unwrap_or(
    status_text(
      job_id,
      "",
      "missing",
      false,
      false,
      false,
      error="job not found",
    ),
  )
}

///|
fn next_job_id(state : DaemonState) -> String {
  let job_id = "job-\{state.next_job_id}"
  state.next_job_id = state.next_job_id + 1
  job_id
}

///|
async fn daemon_health(port : Int) -> Bool {
  try {
    let (response, body) = @http.get("http://127.0.0.1:\{port}/health")
    response.code == 200 && body.text().trim(char_set="\r\n ") == "ok"
  } catch {
    _ => false
  }
}

///|
async fn read_running_daemon_port() -> Int? raise Error {
  guard read_text_if_exists(daemon_info_path()) is Some(text)
  guard parse_daemon_info(text) is Some((_pid, port))
  if daemon_health(port) {
    Some(port)
  } else {
    None
  }
}

///|
pub async fn daemon_detach() -> Int raise Error {
  ensure_dir(daemon_dir().0)
  ensure_dir(jobs_dir().0)
  match read_running_daemon_port() {
    Some(port) => {
      println("daemon already running on port \{port}")
      return port
    }
    None => ()
  }

  let log_stdout = @process.redirect_to_file(
    daemon_log_path(),
    create=0o644,
    append=true,
  )
  let log_stderr = @process.redirect_to_file(
    daemon_log_path(),
    create=0o644,
    append=true,
  )
  let cwd = get_current_dir()
  let _pid = @process.spawn_orphan(
    "moon",
    ["run", "src2", "--", "daemon", "serve"],
    stdout=log_stdout,
    stderr=log_stderr,
    cwd~,
  )

  @async.with_timeout(30_000, () => {
    for ;; {
      match read_running_daemon_port() {
        Some(port) => break port
        None => @async.sleep(250)
      }
    }
  })
}

///|
async fn start_job(
  group : @async.TaskGroup[Unit],
  state : DaemonState,
  no_build~ : Bool,
  is_experimental~ : Bool,
  save~ : Bool,
) -> String raise Error {
  let job_id = next_job_id(state)
  let tag = get_tag(is_experimental)
  let job_path = job_dir(job_id).0
  ensure_dir(job_path)
  write_text(
    job_status_path(job_id),
    status_text(job_id, tag, "queued", save, no_build, is_experimental),
  )
  let cwd = state.cwd
  let args = ["run", "src2", "--", "internal-job"]
  if save {
    args.push("--save")
  }
  if is_experimental {
    args.push("--exp")
  }
  if no_build {
    args.push("--no-build")
  }
  let stdout_log = @process.redirect_to_file(
    job_log_path(job_id),
    create=0o644,
    append=true,
  )
  let stderr_log = @process.redirect_to_file(
    job_log_path(job_id),
    create=0o644,
    append=true,
  )
  group.spawn_bg(no_wait=true, () => {
    write_text(
      job_status_path(job_id),
      status_text(job_id, tag, "running", save, no_build, is_experimental),
    )
    let exit_code = @process.run(
      "moon",
      args,
      cwd~,
      stdout=stdout_log,
      stderr=stderr_log,
    ) catch {
      error => {
        write_text(
          job_status_path(job_id),
          status_text(
            job_id,
            tag,
            "failed",
            save,
            no_build,
            is_experimental,
            exit_code="-1",
            error=error.to_string(),
          ),
        )
        return
      }
    }
    if exit_code == 0 {
      let artifact = if save { Some(image_path(tag)) } else { None }
      write_text(
        job_status_path(job_id),
        status_text(
          job_id,
          tag,
          "success",
          save,
          no_build,
          is_experimental,
          artifact?,
          exit_code="0",
        ),
      )
    } else {
      write_text(
        job_status_path(job_id),
        status_text(
          job_id,
          tag,
          "failed",
          save,
          no_build,
          is_experimental,
          exit_code=exit_code.to_string(),
          error="internal job failed",
        ),
      )
    }
  })
  job_id
}

///|
async fn response_ok(
  conn : @http.ServerConnection,
  text : String,
  code? : Int = 200,
) -> Unit raise Error {
  conn
  ..send_response(code, "OK", extra_headers={ "Content-Type": "text/plain" })
  ..write(text)
  .end_response()
}

///|
async fn response_not_found(
  conn : @http.ServerConnection,
  text : String,
) -> Unit raise Error {
  conn
  ..send_response(404, "NotFound", extra_headers={
    "Content-Type": "text/plain",
  })
  ..write(text)
  .end_response()
}

///|
pub async fn daemon_serve() -> Unit raise Error {
  ensure_dir(daemon_dir().0)
  ensure_dir(jobs_dir().0)
  let info_path = daemon_info_path()
  let info_file = @fs.open(info_path, mode=WriteOnly, create=0o644)
  guard info_file.try_lock(Exclusive) else {
    println("daemon already running")
    info_file.close()
    return
  }
  let cwd = get_current_dir()
  let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
  let port = server.addr.port()
  info_file.write(info_text(0, port))
  info_file.sync()
  let state = DaemonState::{ cwd, next_job_id: 1 }

  println("devenv daemon listening on 127.0.0.1:\{port}")
  @async.with_task_group(group => {
    server.run_forever((request, _body, conn) => {
      let path = strip_query(request.path)
      let query = parse_query(request.path)
      match (request.meth, path.split("/").to_array()) {
        (Get, ["", "health"]) => response_ok(conn, "ok\n")
        (Post, ["", "build"]) => {
          let job_id = start_job(
            group,
            state,
            no_build=parse_bool(query.get("no_build")),
            is_experimental=parse_bool(query.get("exp")),
            save=parse_bool(query.get("save")),
          )
          response_ok(conn, job_id + "\n")
        }
        (Get, ["", "job", job_id]) => {
          let job_id = job_id.to_string()
          if @fs.exists(job_status_path(job_id)) {
            response_ok(conn, read_status(job_id))
          } else {
            response_not_found(conn, "job not found\n")
          }
        }
        (Get, ["", "job", job_id, "log"]) =>
          match read_text_if_exists(job_log_path(job_id.to_string())) {
            Some(text) => response_ok(conn, text)
            None => response_not_found(conn, "job log not found\n")
          }
        _ => response_not_found(conn, "unknown endpoint\n")
      }
    })
  })
}

///|
fn daemon_url(port : Int, path : String) -> String {
  "http://127.0.0.1:\{port}\{path}"
}

///|
pub async fn daemon_build(
  no_build : Bool,
  is_experimental : Bool,
  save : Bool,
  wait : Bool,
) -> Unit raise Error {
  let port = daemon_detach()
  let path = "/build?save=\{bool_text(save)}&exp=\{bool_text(is_experimental)}&no_build=\{bool_text(no_build)}"
  let (response, body) = @http.post(daemon_url(port, path), b"")
  if response.code != 200 {
    raise Failure::Failure("daemon build request failed: \{response.code}")
  }
  let job_id = body.text().trim(char_set="\r\n ")
  println(job_id)
  if wait {
    daemon_wait(job_id.to_string())
  }
}

///|
pub async fn daemon_job(job_id : String) -> Unit raise Error {
  let port = daemon_detach()
  let (response, body) = @http.get(daemon_url(port, "/job/\{job_id}"))
  if response.code != 200 {
    raise Failure::Failure("job lookup failed: \{response.code}")
  }
  @stdio.stdout.write(body.binary())
}

///|
pub async fn daemon_log(job_id : String) -> Unit raise Error {
  let port = daemon_detach()
  let (response, body) = @http.get(daemon_url(port, "/job/\{job_id}/log"))
  if response.code != 200 {
    raise Failure::Failure("job log lookup failed: \{response.code}")
  }
  @stdio.stdout.write(body.binary())
}

///|
pub async fn daemon_wait(job_id : String) -> Unit raise Error {
  let port = daemon_detach()
  for ;; {
    let (response, body) = @http.get(daemon_url(port, "/job/\{job_id}"))
    if response.code != 200 {
      raise Failure::Failure("job wait failed: \{response.code}")
    }
    let text = body.text()
    let values = parse_kv(text)
    let state = values.get("state").unwrap_or("missing")
    println(text.trim(char_set="\r\n "))
    if state == "success" {
      return
    }
    if state == "failed" || state == "missing" {
      raise Failure::Failure("job \{job_id} ended in state \{state}")
    }
    @async.sleep(1_000)
  }
}

///|
pub async fn internal_job(
  no_build : Bool,
  is_experimental : Bool,
  save_artifact : Bool,
) -> Unit raise Error {
  if save_artifact {
    save(no_build, is_experimental)
  } else {
    if no_build {
      raise Failure::Failure("--no-build is only valid together with --save")
    }
    build(is_experimental)
  }
}
