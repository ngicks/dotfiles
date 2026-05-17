{ lib
, buildGo126Module
, fetchFromGitHub
}:

buildGo126Module rec {
  pname = "cmdman";
  version = "0.0.3";

  src = fetchFromGitHub {
    owner = "ngicks";
    repo = "cmdman";
    rev = "v${version}";
    hash = "sha256-01gm/pbKhIISeX4bB8LoEXgZAyZNFNy/00h4yowdeV0=";
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
