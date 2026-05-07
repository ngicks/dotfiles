{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "cmdman";
  version = "unstable-2026-05-07";

  src = fetchFromGitHub {
    owner = "ngicks";
    repo = "cmdman";
    rev = "5138c0dba1c3e8743fc4f043c43ae539dfc013a6";
    hash = "sha256-Nw2lD/vmbhMlnl2SAoWHQQcj1x3s+7ZDmOFyxlsoqcQ=";
  };

  vendorHash = lib.fakeHash;
  proxyVendor = true;

  subPackages = [
    "cmd/cmdman"
  ];

  meta = with lib; {
    description = "Shell command daemonizer that runs blocking commands in background";
    homepage = "https://github.com/ngicks/cmdman";
    license = licenses.mit;
    mainProgram = "cmdman";
  };
}
