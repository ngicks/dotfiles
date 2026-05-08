if vim.loader then
  vim.loader.enable()
else
  vim.notify("vim.loader doesn't exist.", vim.log.levels.WARN)
end

vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"

vim.keymap.set("", "<Space>", "<Nop>", { silent = true, noremap = true })
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Disabling bunch of unused functions.
for _, plugin in ipairs {
  "2html_plugin",
  "tohtml",
  "getscript",
  "getscriptPlugin",
  "gzip",
  "logipat",
  "netrw",
  "netrwPlugin",
  "netrwSettings",
  "netrwFileHandlers",
  "matchit",
  "tar",
  "tarPlugin",
  "rrhelper",
  "spellfile_plugin",
  "vimball",
  "vimballPlugin",
  "zip",
  "zipPlugin",
  "tutor",
  "rplugin",
  "syntax",
  "synmenu",
  "optwin",
  "compiler",
  "bugreport",
  "ftplugin",
} do
  vim.g["loaded_" .. plugin] = 1
end

require("ngpack").setup(require "ngcfg.plugins")

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "ngcfg.options"

vim.schedule(function()
  require "ngcfg.mappings"
end)
