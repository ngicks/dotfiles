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
    rev = "2a8232df5368eff910c4a0ca767ab2d416b08e35";
    hash = "sha256-y+A+3PGxV4VU4W8pvpZ/sPAFZAtqg3B9HLwrvkjwt+Y=";
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
