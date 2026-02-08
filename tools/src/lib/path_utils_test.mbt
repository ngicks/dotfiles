///|
test "parent_dir: regular path" {
  inspect(@lib.parent_dir("/home/user/project"), content="Some(\"/home/user\")")
}

///|
test "parent_dir: root subdir" {
  inspect(@lib.parent_dir("/home"), content="Some(\"/\")")
}

///|
test "parent_dir: root" {
  inspect(@lib.parent_dir("/"), content="None")
}

///|
test "parent_dir: empty" {
  inspect(@lib.parent_dir(""), content="None")
}

///|
test "parent_dir: trailing slash" {
  inspect(@lib.parent_dir("/home/user/"), content="Some(\"/home\")")
}

///|
test "parent_dir: no slash" {
  inspect(@lib.parent_dir("foo"), content="None")
}

///|
test "extract_front_matter: basic" {
  let content = "---\ntitle: Hello\ntags: test\n---\n# Body\n"
  let result = @lib.extract_front_matter(content, [])
  inspect(result, content="Some(\"title: Hello\\ntags: test\")")
}

///|
test "extract_front_matter: with fields filter" {
  let content = "---\ntitle: Hello\ntags: test\ncreated: 2025-01-01\n---\n# Body\n"
  let result = @lib.extract_front_matter(content, ["tags", "created"])
  inspect(result, content="Some(\"tags: test\\ncreated: 2025-01-01\")")
}

///|
test "extract_front_matter: no front matter" {
  let content = "# Just a heading\nSome text\n"
  let result = @lib.extract_front_matter(content, [])
  inspect(result, content="None")
}

///|
test "split_lines: basic" {
  let lines = @lib.split_lines("a\nb\nc")
  inspect(lines.length(), content="3")
  inspect(lines[0], content="a")
  inspect(lines[2], content="c")
}

///|
test "trim: whitespace" {
  inspect(@lib.trim("  hello  "), content="hello")
  inspect(@lib.trim("hello"), content="hello")
  inspect(@lib.trim(""), content="")
}
