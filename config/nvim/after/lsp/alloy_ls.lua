return {
  -- nixpkgs names the Alloy 6 launcher `alloy6`; nvim-lspconfig expects `alloy`.
  cmd = { "alloy6", "lsp" },
}
