{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "run-in-tmux-popup";
  version = "unstable-2026-01-26";

  src = fetchFromGitHub {
    owner = "ngicks";
    repo = "run-in-tmux-popup";
    rev = "bd95f5dbcacf00bde3f89afd9b34666f6819612c";
    hash = "sha256-ya4XXXbWkuNwDjyRJbXT6EDqu0g256D/wV6jki0MIag=";
  };

  vendorHash = null;

  subPackages = [
    "cmd/tmux-popup-pinentry-curses"
    "cmd/zellij-popup-pinentry-curses"
  ];

  meta = with lib; {
    description = "Launch pinentry-curses in tmux/zellij popup";
    homepage = "https://github.com/ngicks/run-in-tmux-popup";
    license = licenses.mit;
    mainProgram = "tmux-popup-pinentry-curses";
  };
}
