{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "cmdman";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "ngicks";
    repo = "cmdman";
    rev = "v${version}";
    hash = "sha256-Nw2lD/vmbhMlnl2SAoWHQQcj1x3s+7ZDmOFyxlsoqcQ=";
  };

  vendorHash = "sha256-RdrU/GjFujEpGoE+ua3mJa5EcYGgF0TsGq0CLn8ovd0=";
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
