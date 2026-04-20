///|
using @path {type Path}

///|
pub fn ca_file_path() -> String {
  @env.get_env_var("SSL_CERT_FILE").unwrap_or(
    // maybe we can later improve this to search 2-3 distro specifc paths.
    "/etc/ssl/certs/ca-certificates.crt",
  )
}

///|
pub struct Paths {
  cache_root : String
  ca_file : String
}

///|
pub fn Paths::image_dir(self : Self) -> String {
  Path::join(self.cache_root, "image").to_string()
}

///|
pub fn image_file_name(repository : String, tag : String) -> String {
  repository.replace_all(old="/", new="_") + "-" + tag + ".tar.gz"
}

///|
pub fn devenv_image_file_name(tag : String) -> String {
  image_file_name(repository, tag)
}

///|
pub fn Paths::image_path(self : Self, tag : String) -> String {
  Path::join(self.image_dir(), devenv_image_file_name(tag)).to_string()
}

///|
pub fn Paths::ca_file(self : Self) -> String {
  self.ca_file
}

///|
pub struct PathsBuilder {
  mut cache_root : String?
  mut ca_file : String?
}

///|
pub fn PathsBuilder::new() -> PathsBuilder {
  PathsBuilder::{ cache_root: None, ca_file: None }
}

///|
pub fn PathsBuilder::build(self : Self) -> Paths raise Error {
  Paths::{
    cache_root: self.cache_root.unwrap_or(
      Path::join(@os_path.user_cache_dir(), "dotfiles")
      .join("devenv")
      .to_string(),
    ),
    ca_file: self.ca_file.unwrap_or(ca_file_path()),
  }
}

///|
pub fn PathsBuilder::cache_root(self : Self, cache_root : String) -> Unit {
  self.cache_root = Some(cache_root)
}

///|
pub fn PathsBuilder::ca_file(self : Self, ca_file : String) -> Unit {
  self.ca_file = Some(ca_file)
}
