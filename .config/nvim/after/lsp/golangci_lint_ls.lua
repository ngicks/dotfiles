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
}
