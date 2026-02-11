{ lib, buildGoModule }:

buildGoModule {
  pname = "lsp-gw";
  version = "0.1.0";
  src = ../../tools/lsp-gw;
  vendorHash = "sha256-uSoxJv8+yuy8OZKZFxURdU8hGmX5vmf1qQS1ss3oh5E=";
  meta = {
    description = "Go CLI for Neovim LSP gateway";
    mainProgram = "lsp-gw";
  };
}
