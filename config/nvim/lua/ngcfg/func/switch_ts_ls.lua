local M = {}

-- Files a language server navigates into but which never form a project of
-- their own: vendored dependencies, deno's npm cache, the compiler's bundled
-- lib.*.d.ts. Root detection on them either spawns a useless server rooted at
-- the dependency or, lacking any marker, falls into the single-file-is-deno
-- rule.
---@param fname string
function M.is_library_file(fname)
  if fname:find("/node_modules/", 1, true) then
    return true
  end
  if vim.fs.basename(fname):match "^lib%..*%.d%.ts$" then
    return true
  end
  local deno_dir = vim.env.DENO_DIR
    or vim.fs.joinpath(vim.env.XDG_CACHE_HOME or vim.fs.joinpath(vim.env.HOME, ".cache"), "deno")
  return vim.startswith(fname, deno_dir .. "/")
end

-- The client named `name` that should own a library buffer: the one attached
-- to the buffer the jump came from (the alternate buffer at the time the new
-- buffer is set up), else one whose root contains the file (node_modules
-- under a project root).
---@param name string
---@param fname string
---@return vim.lsp.Client?
function M.find_origin_client(name, fname)
  local alt = vim.fn.bufnr "#"
  if alt > 0 and vim.api.nvim_buf_is_valid(alt) then
    local client = vim.lsp.get_clients({ bufnr = alt, name = name })[1]
    if client then
      return client
    end
  end
  for _, client in ipairs(vim.lsp.get_clients { name = name }) do
    if client.root_dir and vim.startswith(fname, client.root_dir .. "/") then
      return client
    end
  end
  return nil
end

-- For use at the top of a root_dir callback. Returns true when bufnr is a
-- library file, in which case the origin client (if any) has been attached
-- and the caller must not start a new server.
---@param name string
---@param bufnr integer
function M.attach_origin_client_if_library(name, bufnr)
  local fname = vim.api.nvim_buf_get_name(bufnr)
  if not M.is_library_file(fname) then
    return false
  end
  local client = M.find_origin_client(name, fname)
  if client then
    vim.lsp.buf_attach_client(bufnr, client.id)
  end
  return true
end

-- return the root directory for fname if **it is a deno project**
-- Otherwise nil.
--
-- Rules:
-- 1. presence of deno.json[c] determines it is a deno project:
-- deno has package.json support, which means mixes of these *.json
-- should indicate the project is in transition from node to deno.
-- 2. presence of package.json[c] determines it is a node project.
-- 3. then it is a deno oriented single typescript file:
-- I have a strong option that every single-typescript file must be run by deno.
--
-- Yes you can check buffer contents and see if it has lines that is accessing to Deno global object.
-- But you know that there's fair chance of false-positive.
-- Multi-runtime projects may check runtime types by presence of certain objects.
-- That's why bascially you do not want to do that.
--
-- I know there's alot more javascript runtime out there like Bun, cloudflare edge something something, etc.
-- TODO: expand if I have to do that?
---@param bufnr integer
function M.find_deno_root_dir(bufnr)
  local fname = vim.api.nvim_buf_get_name(bufnr)
  local droot = vim.fs.root(fname, { "deno.json", "deno.jsonc" })
  if droot then
    return droot
  end
  if vim.fs.root(fname, { "package.json", "package.jsonc" }) then
    return nil
  end
  -- maybe we'd want only an instance per a git repository to run.
  local git = vim.fs.root(fname, { ".git" })
  if git ~= nil then
    return git
  end
  return vim.fn.getcwd() -- Use the current working directory
end

-- returns the root directory for fname if it is pointing to node.js typescript/javascript.
-- It is an opposite of deno_root_dir
---@param bufnr integer
function M.find_node_root_dir(bufnr)
  local fname = vim.api.nvim_buf_get_name(bufnr)
  if M.find_deno_root_dir(bufnr) then
    return nil
  end
  return vim.fs.root(fname, { "package.json", "package.jsonc" })
end

return M
