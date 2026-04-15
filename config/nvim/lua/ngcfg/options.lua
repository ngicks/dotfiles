require("ngcfg.func.scan_conf_dir").load_local_dir({ "ngcfg", "setup" }, true)

vim.schedule(function()
  require("ngcfg.pkg.autoreload").setup {
    interval_ms = 2000,
  }
end)
