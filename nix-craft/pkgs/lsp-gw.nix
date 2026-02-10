{ lib, buildGoModule }:

buildGoModule {
  pname = "lsp-gw";
  version = "0.1.0";
  src = ../../tools/lsp-gw;
  vendorHash = "";
  meta = {
    description = "Go CLI for Neovim LSP gateway";
    mainProgram = "lsp-gw";
  };
}
