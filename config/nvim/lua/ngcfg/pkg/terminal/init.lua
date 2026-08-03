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

-- git is assumed installed here; letting a missing binary raise beats degrading into
-- "not a repository" and silently opening lazygit at the wrong place.
---@param args string[]
---@return string? # trimmed stdout on exit 0, nil otherwise
local function git(args)
  local result = vim.system(vim.list_extend({ "git" }, args)):wait()
  if result.code ~= 0 then
    return nil
  end
  return vim.trim(result.stdout or "")
end

---@param dir string
---@return string[]
local function worktree_list(dir)
  local out = git { "-C", dir, "worktree", "list", "--porcelain" }
  if not out then
    return {}
  end

  local worktrees = {}
  for stanza in vim.gsplit(out, "\n\n", { plain = true, trimempty = true }) do
    local path = stanza:match "^worktree ([^\n]+)"
    -- the container's own `bare` entry is the degraded mode lazygit must not land in, and
    -- `prunable` entries stay listed after their directory is gone. git refuses to mark a
    -- *locked* worktree prunable even once it is gone, so existence is still checked here.
    if path and not stanza:find "\nbare" and not stanza:find "\nprunable" and vim.uv.fs_stat(path) then
      worktrees[#worktrees + 1] = path
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
  -- getcwd keeps reporting a directory that has since been removed, and every git call below
  -- has to chdir into it; without this the failures cascade into opening lazygit at a path
  -- that no longer exists.
  if not vim.uv.fs_stat(cwd) then
    vim.notify("lazygit: working directory does not exist: " .. cwd, vim.log.levels.WARN)
    return
  end

  local root = git { "-C", cwd, "rev-parse", "--show-toplevel" }
  if root then
    return cb(root)
  end

  if git { "-C", cwd, "rev-parse", "--is-bare-repository" } == "true" then
    local candidates = worktree_list(cwd)
    if #candidates == 0 then
      -- opening the bare root itself would drop lazygit into degraded bare mode.
      vim.notify("lazygit: bare repository with no worktrees", vim.log.levels.WARN)
      return
    end
    return pick_worktree(candidates, cb)
  end

  -- a bare container without the `gitdir:` marker file is invisible to git, which only
  -- discovers upward; probe the children rather than reading `.git` markers ourselves.
  local candidates = {}
  for name in vim.fs.dir(cwd) do
    local child = vim.fs.joinpath(cwd, name)
    -- not vim.fs.dir's kind: it reports a symlinked worktree as "link", while fs_stat follows
    -- the link like git itself does.
    local stat = vim.uv.fs_stat(child)
    if stat and stat.type == "directory" then
      local top = git { "-C", child, "rev-parse", "--show-toplevel" }
      -- git resolves symlinks in its output, so compare against the resolved child.
      if top and top == vim.uv.fs_realpath(child) then
        candidates[#candidates + 1] = top
      end
    end
  end
  if #candidates == 0 then
    return cb(cwd)
  end
  pick_worktree(candidates, cb)
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
