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
    lazy = false,
  },
  -- base: thanks nvchad!
  {
    "nvchad/ui",
    lazy = false,
    config = function()
      require "nvchad"
    end,
  },
  {
    "nvchad/base46",
    lazy = false,
    build = function()
      require("base46").load_all_highlights()
    end,
  },
  {
    "nosduco/remote-sshfs.nvim",
    lazy = false,
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
  },
  -- ui
  {
    "nvzone/volt",
  },
  {
    "nvzone/menu",
  },
  {
    "nvzone/minty",
    cmd = { "Huefy", "Shades" },
  },
  {
    "nvim-tree/nvim-web-devicons",
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "User FilePost",
  },

  {
    "folke/which-key.nvim",
    keys = { "<leader>", "<c-w>", '"', "'", "`", "c", "v", "g" },
    cmd = "WhichKey",
  },

  {
    "sindrets/diffview.nvim",
    cmd = "DiffviewOpen",
  },
  -- git stuff
  {
    "lewis6991/gitsigns.nvim",
    event = "User FilePost",
  },

  -- lsp stuff
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
  },

  {
    "neovim/nvim-lspconfig",
    event = "User FilePost",
  },

  -- load luasnips + cmp related in insert mode only
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      {
        -- snippet plugin
        "L3MON4D3/LuaSnip",
        dependencies = "rafamadriz/friendly-snippets",
        opts = { history = true, updateevents = "TextChanged,TextChangedI" },
        config = function(_, opts)
          require("luasnip").config.set_config(opts)
          require "config.luasnip"
        end,
      },

      -- cmp sources plugins
      {
        "saadparwaiz1/cmp_luasnip",
        "hrsh7th/cmp-nvim-lua",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "https://codeberg.org/FelipeLema/cmp-async-path.git",
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    branch = "main",
  },
  {
    "nvim-mini/mini.nvim",
    keys = { "<leader>s" },
  },

  -- management
  {
    "rmagatti/auto-session",
    lazy = false,
  },
  -- LLM integration
  {
    "greggh/claude-code.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "VeryLazy" },
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
    dependencies = { "nvim-treesitter/nvim-treesitter" },
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
    commit = "f65fba733268ffcf9c5b8ac381287eca7c223422",
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
  -- editor for specific formatted files
  { -- database viewer
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
    "lemarsu/sops.nvim",
    cmd = { "Sops" },
  },
  {
    "akinsho/toggleterm.nvim",
    cmd = { "ToggleTerm" },
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
