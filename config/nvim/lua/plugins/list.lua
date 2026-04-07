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
    src = "https://github.com/nvim-lua/plenary.nvim",
    phase = "core",
  },
  -- base: thanks nvchad!
  {
    src = "https://github.com/nvchad/ui",
    phase = "core",
    config = function()
      require "nvchad"
    end,
  },
  {
    src = "https://github.com/nvchad/base46",
    phase = "core",
    build = function()
      require("base46").load_all_highlights()
    end,
  },
  {
    src = "https://github.com/nvim-tree/nvim-web-devicons",
    phase = "core",
  },
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter",
    phase = "core",
    branch = "main",
  },
  {
    src = "https://github.com/rmagatti/auto-session",
    phase = "core",
  },
  -- lsp stuff
  {
    src = "https://github.com/neovim/nvim-lspconfig",
    phase = "core",
  },
  -- completion
  {
    src = "https://github.com/rafamadriz/friendly-snippets",
    phase = "core",
  },
  {
    src = "https://github.com/L3MON4D3/LuaSnip",
    phase = "core",
  },
  {
    src = "https://github.com/saadparwaiz1/cmp_luasnip",
    phase = "core",
  },
  {
    src = "https://github.com/hrsh7th/cmp-nvim-lua",
    phase = "core",
  },
  {
    src = "https://github.com/hrsh7th/cmp-nvim-lsp",
    phase = "core",
  },
  {
    src = "https://github.com/hrsh7th/cmp-buffer",
    phase = "core",
  },
  {
    src = "https://codeberg.org/FelipeLema/cmp-async-path.git",
    phase = "core",
  },
  {
    src = "https://github.com/hrsh7th/nvim-cmp",
    phase = "core",
  },
  {
    src = "https://github.com/moonbit-community/moonbit.nvim",
    phase = "core",
  },
  -- ui
  {
    src = "https://github.com/nvzone/volt",
  },
  {
    src = "https://github.com/nvzone/menu",
  },
  {
    src = "https://github.com/nvzone/minty",
  },
  {
    src = "https://github.com/lukas-reineke/indent-blankline.nvim",
  },
  {
    src = "https://github.com/folke/which-key.nvim",
  },
  {
    src = "https://github.com/sindrets/diffview.nvim",
  },
  -- git stuff
  {
    src = "https://github.com/lewis6991/gitsigns.nvim",
  },
  {
    src = "https://github.com/nvim-mini/mini.nvim",
  },
  {
    src = "https://github.com/greggh/claude-code.nvim",
  },
  {
    src = "https://github.com/mfussenegger/nvim-dap",
  },
  {
    src = "https://github.com/nvim-neotest/nvim-nio",
  },
  {
    src = "https://github.com/rcarriga/nvim-dap-ui",
  },
  {
    src = "https://github.com/theHamsta/nvim-dap-virtual-text",
  },
  { -- format file types where lsp is not available.
    src = "https://github.com/stevearc/conform.nvim",
  },
  { -- display lsp symbols, diagnoses
    src = "https://github.com/folke/trouble.nvim",
  },
  -- telescope
  {
    src = "https://github.com/nvim-telescope/telescope.nvim",
  },
  {
    src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim",
  },
  {
    src = "https://github.com/nvim-telescope/telescope-live-grep-args.nvim",
  },
  {
    src = "https://github.com/nosduco/remote-sshfs.nvim",
  },
  -- visual helper
  {
    src = "https://github.com/nvim-tree/nvim-tree.lua",
  },
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter-context",
  },
  {
    src = "https://github.com/petertriho/nvim-scrollbar",
  },
  { -- display breadcrumb list at top of the buffer.
    src = "https://github.com/Bekaboo/dropbar.nvim",
  },
  {
    src = "https://github.com/junegunn/fzf",
  },
  { -- preview for quick list items
    src = "https://github.com/kevinhwang91/nvim-bqf",
  },
  -- renderer
  {
    src = "https://github.com/MeanderingProgrammer/render-markdown.nvim",
  },
  {
    src = "https://github.com/hat0uma/csvview.nvim",
  },
  -- editor for specific formatted files
  {
    src = "https://github.com/tpope/vim-dadbod",
  },
  {
    src = "https://github.com/kristijanhusak/vim-dadbod-completion",
  },
  { -- database viewer
    src = "https://github.com/kristijanhusak/vim-dadbod-ui",
  },
  {
    src = "https://github.com/lemarsu/sops.nvim",
  },
  {
    src = "https://github.com/akinsho/toggleterm.nvim",
  },
  -- memo
  {
    src = "https://github.com/glidenote/memolist.vim",
  },
  {
    src = "https://github.com/delphinus/telescope-memo.nvim",
  },
  -- debug
  { -- gets buffer content then eval in nvim as lua script.
    src = "https://github.com/bfredl/nvim-luadev",
  },
  {
    src = "https://github.com/folke/lazydev.nvim",
  },
}
