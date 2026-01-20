local markers = {
  ".golangci.yml",
  ".golangci.yaml",
  ".golangci.toml",
  ".golangci.json",
}

return {
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local root = vim.fs.root(fname, markers)
    if root then
      on_dir(root)
    end
  end,
  root_markers = markers,
  before_init = function(_, config)
    -- switch version based on config schema.
    -- golangci-lint v2 is relatively new.
    -- So some projects still are sticking to v1,
    -- while some other has been migrated to v2.

    -- check v2 first since basically it is stricter
    -- in some aspect, e.g. required version top element.
    local v2 = vim
      .system({
        "mise",
        "exec",
        "go:github.com/golangci/golangci-lint/v2/cmd/golangci-lint",
        "--",
        "golangci-lint",
        "config",
        "verify",
      })
      :wait()

    if v2.code == 0 then
      config.init_options.command = {
        "mise",
        "exec",
        "go:github.com/golangci/golangci-lint/v2/cmd/golangci-lint",
        "--",
        "golangci-lint",
        "run",
        "--output.json.path=stdout",
        "--show-stats=false",
      }
      return
    end

    local v1 = vim
      .system({
        "mise",
        "exec",
        "go:github.com/golangci/golangci-lint/cmd/golangci-lint",
        "--",
        "golangci-lint",
        "config",
        "verify",
      })
      :wait()

    if v1.code == 0 then
      config.init_options.command = {
        "mise",
        "exec",
        "go:github.com/golangci/golangci-lint/cmd/golangci-lint",
        "--",
        "golangci-lint",
        "run",
        "--out-format",
        "json",
      }
      return
    end

    vim.notify('"golangci-lint config verify" failed for both v1 and v2', vim.log.levels.WARN)
  end,
}
