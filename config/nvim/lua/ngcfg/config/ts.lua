local M = {}

M.languages = {
  "bash",
  "css",
  "dockerfile",
  "dtd",
  "go",
  "html",
  "ini",
  "javascript",
  "json",
  "lua",
  "markdown",
  "markdown_inline",
  -- already handled in moonbit.nvim
  -- "moonbit",
  "nix",
  "proto",
  "python",
  "rust",
  "sql",
  "tmux",
  "toml",
  "typescript",
  "vim",
  "xml",
  "yaml",
}

function M.install()
  require("nvim-treesitter").install(M.languages)
end

return M
