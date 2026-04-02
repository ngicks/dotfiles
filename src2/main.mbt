///|
fn cli() -> @argparse.Command {
  @argparse.Command::new(
    "dotfiles",
    about="Dotfiles CLI tool",
    subcommand_required=true,
    arg_required_else_help=true,
    subcommands=[
      @argparse.Command::new("build", about="Build devenv container image", flags=[
        @argparse.FlagArg::new(
          "exp",
          short='e',
          long="exp",
          about="Build experimental image",
        ),
      ]),
    ],
  )
}

///|
async fn main {
  let matches = cli().parse() catch {
    e => {
      println(e.to_string())
      return
    }
  }
  match matches.subcommand {
    Some(("build", m)) => {
      let is_exp = m.flags.get("exp").unwrap_or(false)
      @devenv.build(is_exp) catch {
        e => println("error: " + e.to_string())
      }
    }
    _ => ()
  }
}
