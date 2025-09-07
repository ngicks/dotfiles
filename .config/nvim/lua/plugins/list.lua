-- General rule:
--
-- lists every plugins
-- init, opts, config, main and build get often big and fat.
-- init.lua creates separate config for each plugin under ./config
-- and merges functons of same name for listed plugins.
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
return {
  { -- utils
    "nvim-lua/plenary.nvim",
  },
  -- management
  {
    "rmagatti/auto-session",
    lazy = false,
  },
  -- AI integration
  {
    "greggh/claude-code.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "VeryLazy" },
  },
  -- lsp
  { -- just sit there!
    "neovim/nvim-lspconfig",
  },
  -- mason misc
  {
    "williamboman/mason.nvim",
    lazy = false,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    event = { "VeryLazy" },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    event = { "VeryLazy" },
  },
  -- dap
  {
    "mfussenegger/nvim-dap",
    dependencies = { "williamboman/mason.nvim" },
    event = { "LspAttach" },
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    event = { "LspAttach" },
  },
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap" },
    event = { "LspAttach" },
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = { "williamboman/mason.nvim" },
    event = { "LspAttach" },
  },
  { -- format file types where lsp is not available.
    "stevearc/conform.nvim",
    event = "BufWritePre",
  },
  { -- display lsp symbols, diagnoses
    "folke/trouble.nvim",
    event = { "LspAttach" },
    cmd = "Trouble",
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
  {
    "folke/lazydev.nvim",
    ft = "lua",
  },
}
