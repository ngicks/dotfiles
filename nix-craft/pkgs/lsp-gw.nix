{ lib, buildGoModule }:

buildGoModule {
  pname = "lsp-gw";
  version = "0.1.0";
  src = ../../tools/lsp-gw;
  vendorHash = "sha256-/Bl4G5STa5lnNntZnMmt+BfES+N7ZYAwC9tzpuqUKcc=";
  meta = {
    description = "Go CLI for Neovim LSP gateway";
    mainProgram = "lsp-gw";
  };
}
