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
    rev = "817f0e1feac528bfe66e35d161f29613203d4098";
    hash = "sha256-5sQx6W/68QDCYtZE6L1gAiJO4Afe+WA/KKncApELXxA=";
  };

  vendorHash = "sha256-2jXbhAzK87W5c4gBMOIeh2qve00fkEWbWasg+sLqohk=";
  proxyVendor = true;

  subPackages = [
    "cmd/tmux-popup-pinentry-curses"
    "cmd/zellij-popup-pinentry-curses"
    "cmd/pickentry"
  ];

  meta = with lib; {
    description = "Run things in tmux/zllij popup";
    homepage = "https://github.com/ngicks/run-in-tmux-popup";
    license = licenses.mit;
    mainProgram = "tmux-popup-pinentry-curses";
  };
}
