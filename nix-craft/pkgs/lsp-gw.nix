{ lib, buildGoModule }:

buildGoModule {
  pname = "lsp-gw";
  version = "0.1.0";
  src = ../../tools/lsp-gw;
  vendorHash = "sha256-DpLpd07Z3CLQmVlMQTunVgu+wP/q2UuenOGZvP+6sfE=";
  meta = {
    description = "Go CLI for Neovim LSP gateway";
    mainProgram = "lsp-gw";
  };
}
