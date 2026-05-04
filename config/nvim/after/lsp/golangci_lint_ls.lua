local cfg = require "ngcfg.config.ls.golangci_lint_ls"

return {
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local root = cfg.find_root(fname)
    if root then
      on_dir(root)
    end
  end,
  root_markers = cfg.config_names,
  before_init = function(_, config)
    -- switch version based on config file.
    -- golangci-lint v2 is relatively new.
    -- So some projects still are sticking to v1,
    -- while some other has been migrated to v2.
    local root = config.root_dir
    local major_version = cfg.detect_config_version(root)

    local cmd

    if major_version == nil then
      vim.notify("failed to detect golangci-lint config version, falling back to v2", vim.log.levels.WARN)
    else
      cmd = cfg.lint_commands[major_version]
    end

    if not cmd then
      cmd = cfg.lint_commands[#cfg.lint_commands]
    end

    config.init_options.command = cmd
  end,
}
