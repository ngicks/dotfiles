require("ngcfg.func.scan_conf_dir").load_local_dir({ "setup" }, true)

vim.schedule(function()
  require("ngcfg.pkg.autoreload").setup {
    interval_ms = 2000,
  }
  require("ngcfg.pkg.toggleterm").setup()
end)
