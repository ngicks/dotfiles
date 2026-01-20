local M = {}
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
M.find_deno_root_dir = function(bufnr)
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
M.find_node_root_dir = function(bufnr)
  local fname = vim.api.nvim_buf_get_name(bufnr)
  if M.find_deno_root_dir(bufnr) then
    return nil
  end
  return vim.fs.root(fname, { "package.json", "package.jsonc" })
end

return M
