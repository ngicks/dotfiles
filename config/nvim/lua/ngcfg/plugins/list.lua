-- General rule:
--
-- lists every plugin in setup order.
-- Each config file is splitted into ./config
-- because often config gets big and fat.
-- Fields, "init", "opts", "config", "main", "pack_changed_pre", "pack_changed"
-- are merged before passed to ngpack module
--
-- phase:
--   "core" = loaded/configured during startup
--   "ui"   = loaded/configured via vim.schedule after startup
--   "lazy" = loaded/configured manually
---@type NgPackSpecPlain[]
return {
  { -- utils
    src = "https://github.com/nvim-lua/plenary.nvim",
    phase = "core",
  },
  -- base: thanks nvchad!
  {
    src = "https://github.com/nvchad/ui",
    phase = "core",
    version = "",
    config = function()
      require "nvchad"
    end,
  },
  {
    src = "https://github.com/nvchad/base46",
    phase = "core",
    version = "",
    pack_changed = function(_s, data)
      if data.kind ~= "delete" then
        -- basically "delete" is inpossible because I only manage by this table.
        require("base46").load_all_highlights()
      end
    end,
  },
  {
    src = "https://github.com/nvim-tree/nvim-web-devicons",
    phase = "core",
  },
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter",
    phase = "core",
    version = "main",
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
    version = "",
  },
  {
    src = "https://github.com/L3MON4D3/LuaSnip",
    phase = "core",
    dep = { "https://github.com/rafamadriz/friendly-snippets" },
  },
  {
    src = "https://github.com/saadparwaiz1/cmp_luasnip",
    phase = "core",
    version = "",
  },
  {
    src = "https://github.com/hrsh7th/cmp-nvim-lua",
    phase = "core",
    version = "",
  },
  {
    src = "https://github.com/hrsh7th/cmp-nvim-lsp",
    phase = "core",
    version = "",
  },
  {
    src = "https://github.com/hrsh7th/cmp-buffer",
    phase = "core",
    version = "",
  },
  {
    src = "https://codeberg.org/FelipeLema/cmp-async-path.git",
    phase = "core",
    version = "",
  },
  {
    src = "https://github.com/hrsh7th/nvim-cmp",
    phase = "core",
  },
  {
    src = "https://github.com/moonbit-community/moonbit.nvim",
    phase = "core",
    version = "",
  },
  -- ui
  {
    src = "https://github.com/nvzone/volt",
    version = "",
  },
  {
    src = "https://github.com/nvzone/menu",
    version = "",
  },
  {
    src = "https://github.com/nvzone/minty",
    version = "",
  },
  {
    src = "https://github.com/lukas-reineke/indent-blankline.nvim",
  },
  {
    src = "https://github.com/folke/which-key.nvim",
  },
  {
    src = "https://github.com/MunifTanjim/nui.nvim",
  },
  {
    src = "https://github.com/rcarriga/nvim-notify",
  },
  {
    src = "https://github.com/folke/noice.nvim",
    dep = { "https://github.com/MunifTanjim/nui.nvim" },
  },
  {
    src = "https://github.com/sindrets/diffview.nvim",
    version = "",
  },
  -- git stuff
  {
    src = "https://github.com/lewis6991/gitsigns.nvim",
  },
  {
    src = "https://github.com/nvim-mini/mini.nvim",
  },
  {
    src = "https://github.com/mfussenegger/nvim-dap",
  },
  {
    src = "https://github.com/nvim-neotest/nvim-nio",
  },
  {
    src = "https://github.com/rcarriga/nvim-dap-ui",
    dep = {
      "https://github.com/mfussenegger/nvim-dap",
      "https://github.com/nvim-neotest/nvim-nio",
    },
  },
  {
    src = "https://github.com/theHamsta/nvim-dap-virtual-text",
    version = "",
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
    version = "",
  },
  {
    src = "https://github.com/nvim-telescope/telescope-live-grep-args.nvim",
    dep = { "https://github.com/nvim-telescope/telescope.nvim" },
  },
  {
    src = "https://github.com/nosduco/remote-sshfs.nvim",
    dep = {
      "https://github.com/nvim-telescope/telescope.nvim",
      "https://github.com/nvim-lua/plenary.nvim",
    },
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
    version = "",
  },
  { -- display breadcrumb list at top of the buffer.
    src = "https://github.com/Bekaboo/dropbar.nvim",
  },
  {
    src = "https://github.com/junegunn/fzf",
  },
  { -- preview for quick list items
    src = "https://github.com/kevinhwang91/nvim-bqf",
    version = "main",
  },
  -- renderer
  {
    src = "https://github.com/MeanderingProgrammer/render-markdown.nvim",
    dep = {
      "https://github.com/nvim-treesitter/nvim-treesitter",
      "https://github.com/nvim-mini/mini.nvim",
    },
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
    version = "",
    dep = { "https://github.com/tpope/vim-dadbod" },
  },
  { -- database viewer
    src = "https://github.com/kristijanhusak/vim-dadbod-ui",
    version = "",
    dep = {
      "https://github.com/tpope/vim-dadbod",
      "https://github.com/kristijanhusak/vim-dadbod-completion",
    },
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
    version = "",
  },
  {
    src = "https://github.com/delphinus/telescope-memo.nvim",
    version = "",
    dep = { "https://github.com/nvim-telescope/telescope.nvim" },
  },
  -- debug
  { -- gets buffer content then eval in nvim as lua script.
    src = "https://github.com/bfredl/nvim-luadev",
    version = "",
  },
  {
    src = "https://github.com/folke/lazydev.nvim",
  },
}
