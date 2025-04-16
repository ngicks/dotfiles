-- General rule:
--
-- lists every plugins
-- opts, configs, inits may be stored in separate lua scripts under ./config.
--
-- orders are
--  - SPEC LOADING
--    - dependencies, enabled, cond, priority
--  - SPEC SETUP
--    - init, opts, config, main, build
--  - SPEC LAZY LOADING
--    - lazy, event, cmd, ft, keys
--  - SPEC VERSIONING
--    - branch, tag, commit, version, pin, submodule
--  - SPEC ADVANCED
--    - optional, specs, module, import
local plugins = {
  { -- utils
    "nvim-lua/plenary.nvim",
  },
  -- management
  {
    "rmagatti/auto-session",
    lazy = false,
  },
  -- lsp
  {
    "neovim/nvim-lspconfig",
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    event = { "VeryLazy" },
  },
  {
    "mfussenegger/nvim-dap",
    dependencies = { "williamboman/mason.nvim" },
    event = { "LspAttach" },
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = { "williamboman/mason.nvim" },
    event = { "VeryLazy" },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    event = { "VeryLazy" },
  },
  { -- java
    "mfussenegger/nvim-jdtls",
    ft = { "java" },
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
    },
  },
  { -- format file types where lsp is not available.
    "stevearc/conform.nvim",
    event = "BufWritePre",
  },
  { -- inject non-lsp tools as lsp client
    "mfussenegger/nvim-lint",
    event = "BufWritePost",
  },
  { -- display lsp symbols, diagnoses
    "folke/trouble.nvim",
    event = { "LspAttach" },
    cmd = "Trouble",
  },
  { -- list symbols in the current buffer in floating window. search and jump
    "bassamsdata/namu.nvim",
    event = { "LspAttach" },
  },
  -- telescope
  {
    "nvim-telescope/telescope.nvim",
  },
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    keys = "<leader>",
  },
  {
    "nvim-telescope/telescope-live-grep-args.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
  },
  -- visual helper
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeOpen", "NvimTreeToggle", "NvimTreeFocus" },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile" },
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPre", "BufNewFile" },
  },
  {
    "petertriho/nvim-scrollbar",
    event = { "BufReadPre", "BufNewFile" },
  },
  { -- display breadcrumb list at top of the buffer.
    "Bekaboo/dropbar.nvim",
    dependencies = { "nvim-telescope/telescope-fzf-native.nvim" },
    event = { "BufReadPre", "BufNewFile" },
  },
  { -- preview for quick list items
    "kevinhwang91/nvim-bqf",
    dependencies = { "junegunn/fzf" },
    -- Opening quickfix window itself can't be hooked? fall back to VeryLazy to ensure it works
    event = { "QuickFixCmdPre", "VeryLazy" },
  },
  -- renderer
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPost *.md", "BufReadPost *.mdx", "BufNewFile *.md", "BufNewFile *.mdx" },
  },
  {
    "hat0uma/csvview.nvim",
    event = { "BufReadPost *.csv", "BufNewFile *.csv" },
    cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
  },
  { -- database fales
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod" },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" } }, -- Optional
    },
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
    },
  },
  {
    "akinsho/toggleterm.nvim",
  },
  -- memo
  {
    "glidenote/memolist.vim",
    cmd = { "MemoNew" },
  },
  {
    "delphinus/telescope-memo.nvim",
    dependencies = { "glidenote/memolist.vim", "nvim-telescope/telescope.nvim" },
    cmd = { "Telescope memo list", "Telescope memo live_grep" },
  },
  -- debug
  { -- gets buffer content then eval in nvim as lua script.
    "bfredl/nvim-luadev",
  },
}

for _, plugin in ipairs(plugins) do
  local path = plugin[1]:gsub("%.", "_")
  local dir = vim.fn.stdpath "config" .. "/lua/plugins/config/" .. path

  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
  if vim.fn.filereadable(dir .. "/init.lua") == 0 then
    vim.fn.writefile({ "local M = {}", "", "return M" }, dir .. "/init.lua")
  end

  local conf = require("plugins.config." .. path:gsub("/", "."))
  for _, f in ipairs { "init", "opts", "config", "main", "build" } do
    if conf[f] then
      plugin[f] = conf[f]
    end
  end
end

return plugins
