local M = {}
local origins = {}
local deno_roots
local compiler_roots = {}
local navigation = {
  ["textDocument/definition"] = true,
  ["textDocument/declaration"] = true,
  ["textDocument/typeDefinition"] = true,
  ["textDocument/implementation"] = true,
  ["textDocument/references"] = true,
}

local function managed(client)
  return client.name == "denols" or client.name == "tsgo"
end

local function normalize(path)
  return vim.fs.normalize(vim.uv.fs_realpath(path) or path)
end

local function contains(root, path)
  return vim.startswith(path, root:gsub("/+$", "") .. "/")
end

local function cache_roots()
  if deno_roots then
    return deno_roots
  end
  deno_roots = {}
  if vim.fn.executable "deno" == 1 then
    local result = vim.system({ "deno", "info", "--json" }, { text = true }):wait(1000)
    local ok, info = pcall(vim.json.decode, result.stdout or "")
    if result.code == 0 and ok and type(info) == "table" then
      for _, key in ipairs { "modulesCache", "npmCache", "typescriptCache" } do
        if type(info[key]) == "string" then
          table.insert(deno_roots, normalize(info[key]))
        end
      end
    end
  end
  return deno_roots
end

local function compiler_root(cmd)
  local exe = vim.fn.exepath(cmd)
  if exe == "" then
    return
  end
  exe = normalize(exe)
  if compiler_roots[exe] == nil then
    local dir = vim.fs.dirname(exe)
    -- Non-embedded tsgo distributions keep their declarations beside the executable.
    compiler_roots[exe] = vim.uv.fs_stat(vim.fs.joinpath(dir, "lib.d.ts")) and dir or false
  end
  return compiler_roots[exe]
end

function M.is_library_file(fname)
  if vim.startswith(fname, "deno:/") or vim.startswith(fname, "bundled:///") then
    return true
  end
  local path = normalize(fname)
  if vim.fs.normalize(fname):find("/node_modules/", 1, true) or path:find("/node_modules/", 1, true) then
    return true
  end
  for _, root in ipairs(cache_roots()) do
    if contains(root, path) then
      return true
    end
  end
  local commands = { "tsgo" }
  for _, client in ipairs(vim.lsp.get_clients { name = "tsgo" }) do
    local cmd = client.config.cmd
    if type(cmd) == "table" then
      table.insert(commands, cmd[1])
    elseif client.root_dir then
      -- nvim-lspconfig's command function prefers the project-local installation.
      table.insert(commands, vim.fs.joinpath(client.root_dir, "node_modules/.bin/tsgo"))
    end
  end
  for _, cmd in ipairs(commands) do
    local root = compiler_root(cmd)
    if root and contains(root, path) then
      return true
    end
  end
  return false
end

function M.find_client(fname)
  local path = normalize(fname)
  local origin = origins[path]
  if origin then
    local client = vim.lsp.get_client_by_id(origin)
    if client and not client:is_stopped() then
      return client
    end
    origins[path] = nil
  end
  local best, length, ambiguous = nil, 0, false
  for _, client in ipairs(vim.lsp.get_clients()) do
    if managed(client) and client.root_dir then
      local root = normalize(client.root_dir)
      if contains(root, path) then
        if #root > length then
          best, length, ambiguous = client, #root, false
        elseif #root == length then
          ambiguous = true
        end
      end
    end
  end
  if not ambiguous then
    return best
  end
end

local function attach(bufnr, client)
  for _, attached in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    if managed(attached) and attached.id ~= client.id then
      vim.lsp.buf_detach_client(bufnr, attached.id)
    end
  end
  vim.lsp.buf_attach_client(bufnr, client.id)
end

-- Capture provenance before Neovim loads jump targets and discards response client IDs.
function M.track(client)
  if not managed(client) or client._ng_library_tracking then
    return
  end
  client._ng_library_tracking = true
  local request = client.rpc.request
  client.rpc.request = function(method, params, callback, ...)
    if not navigation[method] then
      return request(method, params, callback, ...)
    end
    return request(method, params, function(err, result, ...)
      if err or type(result) ~= "table" then
        return callback(err, result, ...)
      end
      local locations = vim.islist(result) and result or { result }
      for _, location in ipairs(locations) do
        local uri = location.targetUri or location.uri
        if uri then
          local fname = vim.uri_to_fname(uri)
          if M.is_library_file(fname) then
            origins[normalize(fname)] = client.id
            local bufnr = vim.fn.bufnr(fname)
            if bufnr > 0 and vim.api.nvim_buf_is_loaded(bufnr) then
              attach(bufnr, client)
            end
          end
        end
      end
      return callback(err, result, ...)
    end, ...)
  end
end

function M.attach_if_library(name, bufnr)
  local fname = vim.api.nvim_buf_get_name(bufnr)
  if not M.is_library_file(fname) then
    return false
  end
  local client = M.find_client(fname)
  if client and client.name == name then
    attach(bufnr, client)
  end
  return true
end

return M
