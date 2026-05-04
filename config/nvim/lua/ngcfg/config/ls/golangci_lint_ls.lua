local M = {}

M.config_names = {
  ".golangci.yml",
  ".golangci.yaml",
  ".golangci.toml",
  ".golangci.json",
}

M.lint_commands = {
  {
    "mise",
    "exec",
    "go:github.com/golangci/golangci-lint/cmd/golangci-lint",
    "--",
    "golangci-lint",
    "run",
    "--out-format",
    "json",
  },
  {
    "mise",
    "exec",
    "go:github.com/golangci/golangci-lint/v2/cmd/golangci-lint",
    "--",
    "golangci-lint",
    "run",
    "--output.json.path=stdout",
    "--show-stats=false",
  },
}

M.format_commads = {
  {
    "goimports",
  },
  {
    "mise",
    "exec",
    "go:github.com/golangci/golangci-lint/v2/cmd/golangci-lint",
    "--",
    "golangci-lint",
    "fmt",
    "--stdin",
  },
}

---@param source string?
---@return string?
function M.find_root(source)
  if not source or source == "" then
    return nil
  end

  return vim.fs.root(source, M.config_names)
end

---@param root string?
---@return string?
function M.find_config_path(root)
  if not root or root == "" then
    return nil
  end

  for _, marker in ipairs(M.config_names) do
    local path = vim.fs.joinpath(root, marker)
    if vim.fn.filereadable(path) == 1 then
      return path
    end
  end

  return nil
end

---@param source string?
---@return integer?
function M.detect_config_version(source)
  local root = M.find_root(source)
  local config_path = M.find_config_path(root)
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

  local num = tonumber(version)
  if num then
    return num
  end

  return 1
end

return M
