-- let neovim/lsp-config configure them.
local nonCustomizedServers = {
  "html",
  "cssls",
  "marksman",
  "pyright",
  "clangd",
  "rust_analyzer",
}

local servers = {}

local scan = require("plenary.scandir").scan_dir

local files = scan(vim.fn.stdpath "config" .. "/after/lsp", { depth = 1, add_dirs = false })

for _, fileName in ipairs(files) do
  local name = vim.fs.basename(fileName)
  local serverName, occurence = name:gsub("%.lua", "")
  if occurence == 1 then -- Could there be .lua.lua files?
    table.insert(servers, serverName)
  end
end

return vim.list_extend(servers, nonCustomizedServers)
