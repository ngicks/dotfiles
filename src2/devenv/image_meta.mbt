///|
pub struct ImageMeta {
  name : String
  size : Int64
  /// hex-encoded sha256 sum
  sha256 : String
} derive(ToJson, FromJson)

///|
pub async fn ImageMeta::from_path(path : String) -> ImageMeta raise Error {
  let file = @fs.open(path, mode=@fs.ReadOnly)
  defer file.close()
  let size = file.size()

  let sha256 = sha256(file)
  ImageMeta::{ name: @path.Path::basename(path).to_string(), size, sha256 }
}

///|
async fn[T : @io.Reader] sha256(f : T) -> String {
  let digest = @sha256.Digest::new()

  let buf : FixedArray[Byte] = FixedArray::make(32 * 1024, 0)
  for ;; {
    let n = f.read(buf)
    if n <= 0 {
      break
    }
    for i = 0; i < n; i = i + 1 {
      digest.write(buf[i])
    }
  }

  digest.check_sum()
}

///|
async test "sha256" {
  let log = StringBuilder::new()
  let f = @fs.File::open(
  @async.with_task_group(root => {
    let (r, w) = @io.pipe()
    defer r.close()
    root.spawn_bg(() => writer(log, w))
    inspect(r.read_all().text(), content="abcdefghijkl")
  })
}
