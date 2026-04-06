-- General rule:
--
-- lists every plugin in setup order.
-- init, opts, config, main and build get often big and fat.
-- init.lua creates separate config for each plugin under ./config
-- and merges functions of same name for listed plugins.
--
-- keep dependency order flat in this file.
-- phase:
--   "core" = loaded/configured during startup
--   "ui"   = loaded/configured via vim.schedule after startup
return {
  { -- utils
    "nvim-lua/plenary.nvim",
    phase = "core",
  },
  -- base: thanks nvchad!
  {
    "nvchad/ui",
    phase = "core",
    config = function()
      require "nvchad"
    end,
  },
  {
    "nvchad/base46",
    phase = "core",
    build = function()
      require("base46").load_all_highlights()
    end,
  },
  {
    "nvim-tree/nvim-web-devicons",
    phase = "core",
  },
  {
    "nvim-treesitter/nvim-treesitter",
    phase = "core",
    branch = "main",
  },
  {
    "rmagatti/auto-session",
    phase = "core",
  },
  -- lsp stuff
  {
    "neovim/nvim-lspconfig",
    phase = "core",
  },
  -- completion
  {
    "rafamadriz/friendly-snippets",
    phase = "core",
  },
  {
    "L3MON4D3/LuaSnip",
    phase = "core",
  },
  {
    "saadparwaiz1/cmp_luasnip",
    phase = "core",
  },
  {
    "hrsh7th/cmp-nvim-lua",
    phase = "core",
  },
  {
    "hrsh7th/cmp-nvim-lsp",
    phase = "core",
  },
  {
    "hrsh7th/cmp-buffer",
    phase = "core",
  },
  {
    "FelipeLema/cmp-async-path",
    src = "https://codeberg.org/FelipeLema/cmp-async-path.git",
    phase = "core",
  },
  {
    "hrsh7th/nvim-cmp",
    phase = "core",
  },
  {
    "moonbit-community/moonbit.nvim",
    phase = "core",
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
  },
  {
    "lukas-reineke/indent-blankline.nvim",
  },
  {
    "folke/which-key.nvim",
  },
  {
    "sindrets/diffview.nvim",
  },
  -- git stuff
  {
    "lewis6991/gitsigns.nvim",
  },
  {
    "nvim-mini/mini.nvim",
  },
  {
    "greggh/claude-code.nvim",
  },
  {
    "mfussenegger/nvim-dap",
  },
  {
    "nvim-neotest/nvim-nio",
  },
  {
    "rcarriga/nvim-dap-ui",
  },
  {
    "theHamsta/nvim-dap-virtual-text",
  },
  { -- format file types where lsp is not available.
    "stevearc/conform.nvim",
  },
  { -- display lsp symbols, diagnoses
    "folke/trouble.nvim",
  },
  -- telescope
  {
    "nvim-telescope/telescope.nvim",
  },
  {
    "nvim-telescope/telescope-fzf-native.nvim",
  },
  {
    "nvim-telescope/telescope-live-grep-args.nvim",
  },
  {
    "nosduco/remote-sshfs.nvim",
  },
  -- visual helper
  {
    "nvim-tree/nvim-tree.lua",
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
  },
  {
    "petertriho/nvim-scrollbar",
  },
  { -- display breadcrumb list at top of the buffer.
    "Bekaboo/dropbar.nvim",
  },
  {
    "junegunn/fzf",
  },
  { -- preview for quick list items
    "kevinhwang91/nvim-bqf",
  },
  -- renderer
  {
    "MeanderingProgrammer/render-markdown.nvim",
  },
  {
    "hat0uma/csvview.nvim",
  },
  -- editor for specific formatted files
  {
    "tpope/vim-dadbod",
  },
  {
    "kristijanhusak/vim-dadbod-completion",
  },
  { -- database viewer
    "kristijanhusak/vim-dadbod-ui",
  },
  {
    "lemarsu/sops.nvim",
  },
  {
    "akinsho/toggleterm.nvim",
  },
  -- memo
  {
    "glidenote/memolist.vim",
  },
  {
    "delphinus/telescope-memo.nvim",
  },
  -- debug
  { -- gets buffer content then eval in nvim as lua script.
    "bfredl/nvim-luadev",
  },
  {
    "folke/lazydev.nvim",
  },
}
