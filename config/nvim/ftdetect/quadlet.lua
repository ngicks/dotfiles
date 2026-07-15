-- Neovim's runtime only detects Quadlet files as systemd units when they live
-- under the standard Quadlet directories (e.g. ~/.config/containers/systemd);
-- match by extension too so copies edited inside repositories get the same
-- filetype. ".image", ".build", and ".artifact" are omitted as too generic.
vim.filetype.add {
  extension = {
    container = "systemd",
    volume = "systemd",
    kube = "systemd",
    pod = "systemd",
  },
}
