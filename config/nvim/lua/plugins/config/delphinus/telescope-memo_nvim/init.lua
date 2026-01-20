local M = {}

M.config = function()
  if vim.fn.executable "memo" == 0 then
    vim.notify "memo not found, installing with go install ..."
    vim.fn.system { "go", "install", "github.com/mattn/memo@latest" }
    vim.notify "done"
  end

  local dir = vim.fn.expand "~/.config/memo"

  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir)
  end

  local conf_path = dir .. "/config.toml"

  if vim.fn.filereadable(conf_path) == 0 then
    require "plugins.config.glidenote.memolist_vim" -- ensure g setup
    local conf_content = {
      'memodir = "' .. vim.g.memolist_path .. '"',
      'editor = "nvim"',
      "column = 20",
      "width = 0",
      'selectcmd = "fzf"',
      'grepcmd = "grep -nH ${PATTERN} ${FILES}"',
      'memotemplate = "' .. vim.g.memolist_template_dir_path .. '/md.txt"',
      'assetsdir = "."',
      'pluginsdir = "' .. vim.g.memolist_path .. '/plugins"',
      'templatedirfile = ""',
      'templatebodyfile = ""',
    }
    vim.fn.writefile(conf_content, conf_path)
  end

  require("telescope").load_extension "memo"
end

return M
