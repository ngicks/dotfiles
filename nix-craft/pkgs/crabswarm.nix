{ lib
, buildGo126Module
, fetchFromGitHub
}:

buildGo126Module rec {
  pname = "crabswarm";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "ngicks";
    repo = "crabswarm";
    rev = "v${version}";
    hash = "sha256-2zD+5QEUNEHlm7ukH3hgJFKgc3sQiqg4LXDAceBH864=";
  };

  vendorHash = "sha256-C8kLcEVSeVMLXKCIvYOhOTrmixjPBpw3jhzdebAW69k=";
  proxyVendor = true;

  subPackages = [
    "cmd/crabswarm"
  ];

  meta = with lib; {
    description = "Multi-agent coding orchestrator";
    homepage = "https://github.com/ngicks/crabswarm";
    license = licenses.mit;
    mainProgram = "crabswarm";
  };
}
