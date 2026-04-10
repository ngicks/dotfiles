local markers = {
  ".golangci.yml",
  ".golangci.yaml",
  ".golangci.toml",
  ".golangci.json",
}

local function find_config_path(root)
  if not root or root == "" then
    return nil
  end

  for _, marker in ipairs(markers) do
    local path = vim.fs.joinpath(root, marker)
    if vim.fn.filereadable(path) == 1 then
      return path
    end
  end

  return nil
end

local function detect_golangci_lint_major_version(root)
  local config_path = find_config_path(root)
  if not config_path then
    return nil
  end

  -- `golangci-lint config verify` is still the most preferable way to
  -- distinguish v1/v2 configs because it validates against the schema.
  -- In some environments, however, it times out while downloading the
  -- schema file, so we read the top-level `version` field directly.
  local result = vim.system({ "yq", "-r", '.version // ""', config_path }):wait()
  if result.code ~= 0 then
    return nil
  end

  local version = vim.trim(result.stdout or "")
  if version == "2" then
    return 2
  end

  return 1
end

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
    -- switch version based on config file.
    -- golangci-lint v2 is relatively new.
    -- So some projects still are sticking to v1,
    -- while some other has been migrated to v2.
    local root = config.root_dir
    local major_version = detect_golangci_lint_major_version(root)

    if major_version == nil then
      vim.notify("failed to detect golangci-lint config version, falling back to v2", vim.log.levels.WARN)
    end

    if major_version == 1 then
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
  end,
}
