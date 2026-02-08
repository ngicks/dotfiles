///|
let slash : UInt16 = '/'.to_int().to_uint16()

///|
let newline : UInt16 = '\n'.to_int().to_uint16()

///|
let cr : UInt16 = '\r'.to_int().to_uint16()

///|
let space : UInt16 = ' '.to_int().to_uint16()

///|
let tab : UInt16 = '\t'.to_int().to_uint16()

///|
let colon : UInt16 = ':'.to_int().to_uint16()

///|
pub let comma : UInt16 = ','.to_int().to_uint16()

///|
/// Split a path into its parent directory and basename.
/// Returns None if the path has no parent (e.g. "/" or "").
pub fn parent_dir(path : String) -> String? {
  // Remove trailing slashes
  let mut p = path
  while p.length() > 1 && p[p.length() - 1] == slash {
    p = String::unsafe_substring(p, start=0, end=p.length() - 1)
  }
  // Root directory has no parent
  if p == "/" || p == "" {
    return None
  }
  let last_slash = last_index_of_code(p, slash)
  if last_slash < 0 {
    return None
  }
  if last_slash == 0 {
    return Some("/")
  }
  Some(String::unsafe_substring(p, start=0, end=last_slash))
}

///|
/// Find the last index of a char code in a string. Returns -1 if not found.
pub fn last_index_of_code(s : String, code : UInt16) -> Int {
  let mut i = s.length() - 1
  while i >= 0 {
    if s[i] == code {
      return i
    }
    i -= 1
  }
  -1
}

///|
/// Find the last index of a character in a string. Returns -1 if not found.
pub fn last_index_of(s : String, ch : Char) -> Int {
  last_index_of_code(s, ch.to_int().to_uint16())
}

///|
/// Extract YAML front matter from markdown content.
/// Returns the content between the first pair of "---" markers.
/// If `fields` is non-empty, only lines whose key matches one of the fields are included.
pub fn extract_front_matter(content : String, fields : Array[String]) -> String? {
  let lines = split_lines(content)
  let mut in_front_matter = false
  let mut started = false
  let result : Array[String] = []
  for i = 0; i < lines.length(); i = i + 1 {
    let line = lines[i]
    let trimmed = trim(line)
    if trimmed == "---" {
      if not(started) {
        started = true
        in_front_matter = true
        continue i + 1
      } else if in_front_matter {
        // End of front matter
        break
      }
    }
    if in_front_matter {
      if fields.length() == 0 {
        result.push(line)
      } else {
        // Check if this line's key matches any requested field
        let colon_idx = index_of_code(line, colon)
        if colon_idx > 0 {
          let key = trim(String::unsafe_substring(line, start=0, end=colon_idx))
          for j = 0; j < fields.length(); j = j + 1 {
            if key == fields[j] {
              result.push(line)
              break
            }
          }
        }
      }
    }
  }
  if result.length() == 0 {
    return None
  }
  Some(join_lines(result))
}

///|
/// Split a string into lines.
pub fn split_lines(s : String) -> Array[String] {
  let lines : Array[String] = []
  let mut start = 0
  for i = 0; i < s.length(); i = i + 1 {
    if s[i] == newline {
      let end = if i > start && s[i - 1] == cr { i - 1 } else { i }
      lines.push(String::unsafe_substring(s, start=start, end=end))
      start = i + 1
    }
  }
  if start <= s.length() {
    lines.push(String::unsafe_substring(s, start=start, end=s.length()))
  }
  lines
}

///|
/// Find the first index of a char code in a string. Returns -1 if not found.
pub fn index_of_code(s : String, code : UInt16) -> Int {
  for i = 0; i < s.length(); i = i + 1 {
    if s[i] == code {
      return i
    }
  }
  -1
}

///|
/// Find the first index of a character in a string. Returns -1 if not found.
pub fn index_of(s : String, ch : Char) -> Int {
  index_of_code(s, ch.to_int().to_uint16())
}

///|
/// Trim leading and trailing whitespace from a string.
pub fn trim(s : String) -> String {
  let mut start = 0
  let mut end = s.length()
  while start < end && is_whitespace_code(s[start]) {
    start += 1
  }
  while end > start && is_whitespace_code(s[end - 1]) {
    end -= 1
  }
  String::unsafe_substring(s, start=start, end=end)
}

///|
fn is_whitespace_code(c : UInt16) -> Bool {
  c == space || c == tab || c == newline || c == cr
}

///|
/// Join an array of strings with newlines.
pub fn join_lines(lines : Array[String]) -> String {
  let mut result = ""
  for i = 0; i < lines.length(); i = i + 1 {
    if i > 0 {
      result += "\n"
    }
    result += lines[i]
  }
  result
}
