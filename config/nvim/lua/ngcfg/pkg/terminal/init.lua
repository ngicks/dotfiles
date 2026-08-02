local terminal = require "snacks.terminal"

local M = {}

---@param slot string
---@param win table
local function toggle_terminal(slot, win)
  terminal(nil, {
    env = {
      NG_TERM_SLOT = slot,
    },
    win = win,
  })
end

function M.horizontal()
  toggle_terminal("horizontal", {
    position = "bottom",
    height = 0.3,
  })
end

function M.vertical()
  toggle_terminal("vertical", {
    position = "right",
    width = 0.3,
  })
end

function M.floating()
  toggle_terminal("floating", {
    border = "single",
    position = "float",
  })
end

-- snacks keys terminal instances by the literal cwd string, so every path handed to it
-- must go through the same symlink-resolving spelling vim.fn.getcwd(0) already uses.
---@param path string
---@return string
local function canonical(path)
  return vim.fs.normalize(vim.uv.fs_realpath(path) or path)
end

---@param root string
---@return boolean
local function is_bare_repo(root)
  local spawned, proc = pcall(vim.system, { "git", "-C", root, "rev-parse", "--is-bare-repository" })
  if not spawned then
    return false
  end

  local result = proc:wait()
  return result.code == 0 and vim.trim(result.stdout or "") == "true"
end

---@param root string
---@return string[]
local function worktree_list(root)
  local spawned, proc = pcall(vim.system, { "git", "-C", root, "worktree", "list", "--porcelain" })
  if not spawned then
    return {}
  end

  local result = proc:wait()
  if result.code ~= 0 then
    return {}
  end

  local worktrees = {}
  local added = false
  for line in vim.gsplit(result.stdout or "", "\n", { plain = true }) do
    local path = line:match "^worktree (.+)$"
    if path then
      -- prunable entries stay listed after their directory is gone.
      added = vim.fn.isdirectory(path) == 1
      if added then
        worktrees[#worktrees + 1] = canonical(path)
      end
    elseif line == "bare" and added then
      -- porcelain marks the container itself with a `bare` line right after its `worktree` line.
      worktrees[#worktrees] = nil
      added = false
    end
  end
  return worktrees
end

---@param dir string
---@return string[]
local function worktrees_under(dir)
  local worktrees = {}
  for name in vim.fs.dir(dir) do
    local path = vim.fs.joinpath(dir, name)
    if vim.uv.fs_stat(vim.fs.joinpath(path, ".git")) then
      worktrees[#worktrees + 1] = canonical(path)
    end
  end
  return worktrees
end

---@param candidates string[] non-empty
---@param cb fun(root: string)
local function pick_worktree(candidates, cb)
  if #candidates == 1 then
    return cb(candidates[1])
  end
  vim.ui.select(candidates, { prompt = "lazygit worktree" }, function(choice)
    if choice then
      cb(choice)
    end
  end)
end

---@param cb fun(root: string)
local function resolve_git_root(cb)
  local cwd = vim.fn.getcwd(0)
  if cwd == "" then
    vim.notify("lazygit: cannot determine the working directory", vim.log.levels.WARN)
    return
  end

  cwd = canonical(cwd)
  local root = vim.fs.root(cwd, ".git")
  if root == nil then
    -- a bare container without the `gitdir:` marker file is invisible to vim.fs.root,
    -- which only walks upward; look for worktrees one level down instead.
    local candidates = worktrees_under(cwd)
    if #candidates == 0 then
      return cb(cwd)
    end
    return pick_worktree(candidates, cb)
  end

  root = canonical(root)
  -- only a plain top-level checkout is ruled out this cheaply; linked worktrees and bare
  -- containers both carry a `.git` file and still go through the check below.
  if vim.fn.isdirectory(vim.fs.joinpath(root, ".git")) == 1 then
    return cb(root)
  end
  if is_bare_repo(root) then
    local candidates = worktree_list(root)
    if #candidates == 0 then
      -- opening the bare root itself would drop lazygit into degraded bare mode.
      vim.notify("lazygit: bare repository with no worktrees", vim.log.levels.WARN)
      return
    end
    return pick_worktree(candidates, cb)
  end
  cb(root)
end

function M.lazygit()
  resolve_git_root(function(root)
    require "snacks.lazygit" {
      cwd = root,
      win = {
        border = "single",
        on_buf = function(self)
          vim.keymap.set({ "n", "t" }, "<C-q>", function()
            self:hide()
          end, { buffer = self.buf, silent = true })
        end,
      },
    }
  end)
end

return M
