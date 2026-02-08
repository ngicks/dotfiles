///|
/// rg-front-matter: Extract YAML front matter from markdown files.
///
/// Designed as an `rg --pre` preprocessor.
/// Currently, moonrun's WASI does not support reading arbitrary files,
/// so the shell wrapper handles file I/O and passes content via args.
///
/// Usage: rg-front-matter [--fields=key1,key2] <file-content>
/// Prints extracted front matter to stdout.
fn main {
  let args = @env.args()
  if args.length() < 2 {
    return
  }
  let mut fields : Array[String] = []
  let mut content_idx = 1
  // Parse --fields flag
  if args.length() > 2 && args[1].has_prefix("--fields=") {
    let fields_str = String::unsafe_substring(args[1], start=9, end=args[1].length())
    fields = parse_comma_list(fields_str)
    content_idx = 2
  }
  if content_idx >= args.length() {
    return
  }
  let content = args[content_idx]
  match @lib.extract_front_matter(content, fields) {
    Some(fm) => println(fm)
    None => ()
  }
}

///|
fn parse_comma_list(s : String) -> Array[String] {
  let result : Array[String] = []
  let mut start = 0
  for i = 0; i < s.length(); i = i + 1 {
    if s[i] == @lib.comma {
      let item = @lib.trim(String::unsafe_substring(s, start=start, end=i))
      if item.length() > 0 {
        result.push(item)
      }
      start = i + 1
    }
  }
  let last = @lib.trim(String::unsafe_substring(s, start=start, end=s.length()))
  if last.length() > 0 {
    result.push(last)
  }
  result
}
