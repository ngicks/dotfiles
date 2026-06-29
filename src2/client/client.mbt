///|
/// Resolve the running server's base URL from the runtime state file.
async fn server_url() -> String raise Error {
  match @serverstate.read() {
    Some(info) => info.url
    None =>
      raise Failure::Failure(
        "no running dotfiles server (state file \{@serverstate.state_path()} not found); start one with `dotfiles server serve`",
      )
  }
}

///|
/// POST a JSON body to `path` on the server and print status + response body.
async fn post_json(path : String, body : Json) -> Unit raise Error {
  let url = server_url() + path
  let (resp, data) = @http.post(url, body.stringify(), headers={
    "content-type": "application/json",
  })
  println("HTTP \{resp.code} \{resp.reason}")
  println(data.text())
}

///|
/// Ask the server to build the devenv image.
pub async fn devenv_build(experimental : Bool, wait : Bool) -> Unit raise Error {
  post_json("/devenv/build", { "experimental": experimental, "wait": wait })
}

///|
/// Ask the server to build the devenv image on `remote` and pull it locally.
pub async fn devenv_pull(
  remote : String,
  experimental : Bool,
  wait : Bool,
) -> Unit raise Error {
  post_json("/devenv/pull", {
    "remote": remote,
    "experimental": experimental,
    "wait": wait,
  })
}
