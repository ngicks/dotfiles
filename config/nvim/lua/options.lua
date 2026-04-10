require("func.scan_conf_dir").load_local_dir({ "setup" }, true)

vim.schedule(function()
  require("ngcfg.pkg.toggleterm").setup()
end)
