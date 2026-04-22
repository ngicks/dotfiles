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
  let digest = @sha2.Sha256::new()

  let buf : FixedArray[Byte] = FixedArray::make(32 * 1024, 0)
  for ;; {
    let n = f.read(buf)
    if n <= 0 {
      break hex(digest.finalize())
    }
    digest.update(buf[:n].iter().map(x => x.to_uint()).collect())
  }
}

///|
let digits = "0123456789abcdef"

///|
fn hex(bin : FixedArray[UInt]) -> String {
  let s = StringBuilder::new()
  for _, b in bin {
    s.write_char(digits[(b.reinterpret_as_int() >> 4) % 16].to_char().unwrap())
    s.write_char(digits[b.reinterpret_as_int() % 16].to_char().unwrap())
  }
  s.to_string()
}

///|
async test "sha256" {
  @async.with_task_group(root => {
    let (r, w) = @io.pipe()
    root.add_defer(() => r.close())
    root.spawn_bg(() => {
      w.write(@utf8.encode("abcdefghijkl\n"))
      w.close()
    })
    inspect(
      sha256(r),
      content="6cd0fe73aecda67f987bc42c5fd158fd08eb31b0645432b1afee4be2cbae380d",
    )
  })
}
