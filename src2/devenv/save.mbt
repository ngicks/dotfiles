///|
pub fn cache_dir_path() -> String {
  image_dir().0
}

///|
pub async fn save(no_build : Bool, is_experimental : Bool) -> Unit raise Error {
  let tag = get_tag(is_experimental)
  let image_name = "localhost/devenv/devenv:\{tag}"
  if !no_build {
    build(is_experimental)
  } else {
    println("skipping build, saving existing image \{image_name}")
  }

  ensure_dir(image_dir().0)
  let file_path = image_path(tag)
  if @fs.exists(file_path) {
    println("already saved: \{file_path}")
    return
  }

  let tmp_path = file_path + ".tmp"
  println("saving \{image_name} to \{file_path}")

  @async.with_task_group(group => {
    let (podman_stdout, podman_writer) = @process.read_from_process()
    let (gzip_stdin, gzip_writer) = @process.write_to_process()
    let gzip_output = @process.redirect_to_file(
      tmp_path,
      create=0o644,
      truncate=true,
    )
    defer podman_stdout.close()
    defer gzip_writer.close()
    let podman = @process.spawn(
      group,
      "podman",
      ["save", image_name],
      stdout=podman_writer,
    )
    let gzip = @process.spawn(
      group,
      "gzip",
      [],
      stdin=gzip_stdin,
      stdout=gzip_output,
    )
    group.spawn_bg(() => gzip_writer.write_reader(podman_stdout))
    let podman_code = podman.wait()
    let gzip_code = gzip.wait()
    if podman_code != 0 {
      raise Failure::Failure("podman save failed")
    }
    if gzip_code != 0 {
      raise Failure::Failure("gzip failed")
    }
  })

  if @fs.exists(file_path) {
    @fs.remove(file_path)
  }
  run_checked("mv", [tmp_path, file_path])
  println("saved \{file_path}")
}
