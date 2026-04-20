///|
fn cli() -> @argparse.Command {
  @argparse.Command(
    "dotfiles",
    arg_required_else_help=true,
    subcommand_required=true,
    subcommands=[
      @argparse.Command("build", flags=[@argparse.FlagArg("exp", short='e')]),
      @argparse.Command("save", flags=[
        @argparse.FlagArg("exp", short='e'),
        @argparse.FlagArg("no-build"),
      ]),
      @argparse.Command(
        "pull",
        flags=[
          @argparse.FlagArg("exp", short='e'),
          @argparse.FlagArg("no-build"),
        ],
        positionals=[@argparse.PositionArg("remote")],
      ),
      @argparse.Command(
        "daemon",
        arg_required_else_help=true,
        subcommand_required=true,
        subcommands=[
          @argparse.Command("serve"),
          @argparse.Command("detach"),
          @argparse.Command("build", flags=[
            @argparse.FlagArg("no-build"),
            @argparse.FlagArg("exp", short='e'),
            @argparse.FlagArg("save"),
            @argparse.FlagArg("wait"),
          ]),
          @argparse.Command("job", positionals=[@argparse.PositionArg("job-id")]),
          @argparse.Command("log", positionals=[@argparse.PositionArg("job-id")]),
          @argparse.Command("wait", positionals=[
            @argparse.PositionArg("job-id"),
          ]),
        ],
      ),
      @argparse.Command("internal-job", flags=[
        @argparse.FlagArg("no-build"),
        @argparse.FlagArg("exp", short='e'),
        @argparse.FlagArg("save"),
      ]),
    ],
  )
}

///|
fn has_flag(matches : @argparse.Matches, name : String) -> Bool {
  matches.flags.get_or_default(name, false)
}

///|
fn required_value(
  matches : @argparse.Matches,
  name : String,
) -> String raise Error {
  match matches.values.get(name) {
    Some([value, ..]) => value
    _ => raise Failure::Failure("missing required argument: \{name}")
  }
}

///|
async fn dispatch(matches : @argparse.Matches) -> Unit {
  match matches.subcommand {
    Some(("build", sub)) => @devenv.build(has_flag(sub, "exp"))
    Some(("save", sub)) =>
      @devenv.save(
        @devenv.PathsBuilder::new().build(),
        has_flag(sub, "no-build"),
        has_flag(sub, "exp"),
      )
    Some(("pull", sub)) =>
      @devenv.pull(
        @devenv.PathsBuilder::new().build(),
        required_value(sub, "remote"),
        has_flag(sub, "no-build"),
        has_flag(sub, "exp"),
      )
    Some(("daemon", daemon)) =>
      match daemon.subcommand {
        Some(("serve", _)) => @devenv.daemon_serve()
        Some(("detach", _)) => ignore(@devenv.daemon_detach())
        Some(("build", sub)) =>
          @devenv.daemon_build(
            has_flag(sub, "no-build"),
            has_flag(sub, "exp"),
            has_flag(sub, "save"),
            has_flag(sub, "wait"),
          )
        Some(("job", sub)) => @devenv.daemon_job(required_value(sub, "job-id"))
        Some(("log", sub)) => @devenv.daemon_log(required_value(sub, "job-id"))
        Some(("wait", sub)) =>
          @devenv.daemon_wait(required_value(sub, "job-id"))
        _ => fail("missing daemon subcommand")
      }
    Some(("internal-job", sub)) =>
      @devenv.internal_job(
        has_flag(sub, "no-build"),
        has_flag(sub, "exp"),
        has_flag(sub, "save"),
      )
    _ => fail("missing command")
  }
}

///|
async fn main {
  let matches = cli().parse() catch {
    e => {
      println(e.to_string())
      return
    }
  }
  dispatch(matches) catch {
    e => println("error: " + e.to_string())
  }
}
