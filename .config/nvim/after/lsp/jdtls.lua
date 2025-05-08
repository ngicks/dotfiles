local function find_root(bufnr)
  local source = vim.api.nvim_buf_get_name(bufnr)
  local root_markers = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle", ".project" }
  local root_dir = vim.fs.root(vim.fs.dirname(source), root_markers)

  -- jdtls looks for "gradle/wrapper/gradle-wrapper.properties"
  -- some project only holds wrapper only on top directory while there's many sub-gradle projects
  local next_up = root_dir
  while next_up ~= nil and next_up ~= "" and next_up ~= "/" do
    local s = vim.uv.fs_stat(next_up .. "/gradle/wrapper/gradle-wrapper.properties")
    if s ~= nil then
      root_dir = next_up
      break
    end
    next_up = vim.fs.root(vim.fs.dirname(next_up), root_markers)
  end

  return root_dir
end

return {
  root_dir = function(bufnr, on_dir)
    local root = find_root(bufnr)
    if root and root ~= "" then
      on_dir(root)
    end
  end,
  init_options = {
    bundles = vim.split(
      vim.fn.glob(vim.fn.expand "$HOME" .. "/.local/jdtls/vscode-pde-0.8.0/extension/server/*.jar"),
      "\n"
    ),
  },
}
