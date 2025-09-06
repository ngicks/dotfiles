-- let neovim/lsp-config configure them.
local nonCustomizedServers = {
  "lua_ls",
  "html",
  "cssls",
  "marksman", -- markdown
  "taplo", -- toml
  "pyright",
  "clangd",
  "rust_analyzer",
}

local function get_servers()
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
end

local function get_tools()
  local merge = require("func.table").insert_unique
  local tools = {}
  local loaded = require("func.scan_conf_dir").load_local_dir("config/ls-tools", true)
  for _, ent in ipairs(loaded) do
    tools = merge(tools, ent.tool)
  end
  return tools
end

return {
  lsp = get_servers(),
  tools = get_tools(),
}
