local M = {}
local util = require "ngpack.util"

---@class NgPackLockDesync
---@field name string
---@field path string
---@field expected string
---@field actual string
---@field message string

---@class NgPackLockDropOpts
---@field names? string[]

---@class NgPackLockPruneOrphansOpts
---@field names? string[]

---@class NgPackLockPruneDesyncOpts
---@field names? string[]

---Return the vim.pack lockfile path under the current config directory.
---@return string
local function get_lockfile_path()
  return vim.fs.joinpath(vim.fn.stdpath "config", "nvim-pack-lock.json")
end

---Run a git command inside a plugin repository and return trimmed stdout.
---@param cmd string[]
---@param cwd? string
---@return boolean ok
---@return string result
local function git_cmd(cmd, cwd)
  cmd = vim.list_extend({ "git", "-c", "gc.auto=0" }, cmd)

  local env = vim.fn.environ() ---@type table<string, string>
  env.GIT_DIR, env.GIT_WORK_TREE = nil, nil

  local out = vim
    .system(cmd, {
      cwd = cwd,
      text = true,
      env = env,
      clear_env = true,
    })
    :wait()

  local stdout = (out.stdout or ""):gsub("\n+$", "")
  local stderr = (out.stderr or ""):gsub("\n+$", "")
  if out.code ~= 0 then
    return false, stderr ~= "" and stderr or stdout
  end

  return true, stdout
end

---Read and decode `nvim-pack-lock.json`.
---@return vim.pack.Lock|nil
---@return string? err
local function read_lockfile()
  local path = get_lockfile_path()
  if vim.fn.filereadable(path) ~= 1 then
    return nil, ("lockfile not found: %s"):format(path)
  end

  local ok_read, text = pcall(vim.fn.readblob, path)
  if not ok_read then
    return nil, ("failed to read lockfile: %s"):format(path)
  end

  local ok_parse, data = pcall(vim.json.decode, text)
  if not ok_parse then
    return nil, ("failed to parse lockfile: %s"):format(data)
  end

  if type(data) ~= "table" or type(data.plugins) ~= "table" then
    return nil, ("invalid lockfile schema: %s"):format(path)
  end

  return data
end

---Persist the pack lockfile in the same pretty-printed format as vim.pack.
---@param lock vim.pack.Lock
local function write_lockfile(lock)
  local path = get_lockfile_path()
  local fd = assert(vim.uv.fs_open(path, "w", 438))
  local data = vim.json.encode(lock, { indent = "  ", sort_keys = true })
  assert(vim.uv.fs_write(fd, data .. "\n"))
  assert(vim.uv.fs_close(fd))
end

-- removes pack local data dir.
---@param name string pack name
---@return boolean ok
local function delete_pack_data(name)
  local packs = vim.pack.get({ name }, { info = false })

  if #packs == 0 or packs[1].path == nil then
    vim.notify(("name not found by vim.pack.get: %s"):format(name), vim.log.levels.ERROR)
    return false
  end

  local target_path = packs[1].path

  local ok = vim.fn.delete(target_path, "rf") == 0
  if ok ~= 0 then
    vim.notify(("removal failed: %s for pack name %q"):format(target_path, name), vim.log.levels.ERROR)
    return false
  end

  return true
end

---Collect only revision drift between lockfile state and installed plugin repos.
---@return NgPackLockDesync[]|nil
---@return string? err
---@return vim.pack.Lock lock
local function collect_desync()
  local lock, err = read_lockfile()
  if lock == nil then
    return nil, err, {}
  end

  local items = {}
  local plug_dir = util.plug_dir()

  for name, lock_data in pairs(lock.plugins) do
    if type(name) ~= "string" or type(lock_data) ~= "table" then
      goto continue
    end
    if type(lock_data.rev) ~= "string" or type(lock_data.src) ~= "string" then
      goto continue
    end

    local item = {
      name = name,
      path = vim.fs.joinpath(plug_dir, name),
    }

    if vim.fn.isdirectory(item.path) == 1 then
      local ok_git, _ = git_cmd({ "rev-parse", "--git-dir" }, item.path)
      if ok_git then
        local ok_head, head = git_cmd({ "rev-list", "-1", "HEAD" }, item.path)
        if ok_head and lock_data.rev ~= head then
          item.expected = lock_data.rev
          item.actual = head
          item.message = ("rev mismatch: lock=%s disk=%s"):format(lock_data.rev, head)
          items[#items + 1] = item
        end
      end
    end

    ::continue::
  end

  table.sort(items, function(a, b)
    return a.name < b.name
  end)

  return items, nil, lock
end

---Return current revision-desync entries without mutating state.
---@return NgPackLockDesync[]|nil
---@return string? err
---@return vim.pack.Lock? lock
function M.get_desync()
  return collect_desync()
end

---Report current revision drift and populate the quickfix list when present.
---@param report_nominal? boolean
---@return NgPackLockDesync[]|nil
---@return string? err
function M.report_desync(report_nominal)
  local items, err = collect_desync()
  if items == nil or err ~= nil then
    vim.notify(err or "failed", vim.log.levels.ERROR)
    return nil, err
  end

  if #items == 0 then
    if report_nominal then
      vim.notify("nvim-pack-lock.json is in sync with installed plugin repositories", vim.log.levels.INFO)
      vim.fn.setqflist({}, "r", { title = "Pack Lock Desync", items = {} })
    end
    return items
  end

  local qf = {}
  for _, item in ipairs(items) do
    qf[#qf + 1] = {
      filename = get_lockfile_path(),
      lnum = 1,
      col = 1,
      text = ("%s: %s"):format(item.name, item.message),
    }
  end

  vim.fn.setqflist({}, "r", { title = "Pack Lock Desync", items = qf })
  vim.cmd "copen"
  vim.notify(("found %d desynced lock entr%s"):format(#items, #items == 1 and "y" or "ies"), vim.log.levels.WARN)

  return items
end

---Remove desynced lock entries and re-resolve via vim.pack.add.
---@param opts? NgPackLockDropOpts
---@return string[]|nil removed
---@return string? err
function M.drop_desync(opts)
  opts = opts or {}

  local items, err, lock = collect_desync()
  if items == nil then
    vim.notify(err or "failed", vim.log.levels.ERROR)
    return nil, err
  end

  local selected = {} ---@type table<string, boolean>
  local requested = opts.names or {}
  if #requested == 0 then
    for _, item in ipairs(items) do
      selected[item.name] = true
    end
  else
    for _, name in ipairs(requested) do
      selected[name] = true
    end
  end

  local removed = {}
  for _, item in ipairs(items) do
    if selected[item.name] then
      lock.plugins[item.name] = nil
      removed[#removed + 1] = item.name
      selected[item.name] = nil
    end
  end

  table.sort(removed)

  if #removed == 0 then
    if next(selected) ~= nil then
      local missing = vim.tbl_keys(selected)
      table.sort(missing)
      vim.notify(
        ("requested plugins are not currently desynced: %s"):format(table.concat(missing, ", ")),
        vim.log.levels.WARN
      )
    else
      vim.notify("no desynced lock entries to remove", vim.log.levels.INFO)
    end
    return {}
  end

  write_lockfile(lock)
  vim.notify(
    ("removed %d desynced entries from nvim-pack-lock.json: %s"):format(#removed, table.concat(removed, ", ")),
    vim.log.levels.WARN
  )

  local removed_set = {} ---@type table<string, boolean>
  for _, name in ipairs(removed) do
    removed_set[name] = true
  end

  local pack_specs = {} ---@type vim.pack.Spec[]
  for _, plug in ipairs(require("ngpack").list_enabled_pack()) do
    if removed_set[plug.name] then
      pack_specs[#pack_specs + 1] = plug
    end
  end

  if #pack_specs > 0 then
    vim.pack.add(pack_specs, { confirm = false })
  end

  return removed
end

---Complete plugin names for currently desynced lock entries.
---@return string[]
function M.complete_desync()
  local items = select(1, collect_desync()) or {}
  local names = {}
  for _, item in ipairs(items) do
    names[#names + 1] = item.name
  end
  return names
end

---List plugin directories present on disk but absent from the config pack list.
---@return string[]|nil names
---@return string? err
function M.list_orphans()
  local plugs = {} ---@type table<string, vim.pack.Spec>
  for _, plug in pairs(require("ngpack").list_pack()) do
    plugs[plug.name] = plug
  end

  local plug_dir = util.plug_dir()
  if vim.fn.isdirectory(plug_dir) ~= 1 then
    return {}, nil
  end

  local names = {}
  for name, entry_type in vim.fs.dir(plug_dir) do
    if (entry_type == "directory" or entry_type == "link") and plugs[name] == nil then
      names[#names + 1] = name
    end
  end

  table.sort(names)
  return names, nil
end

---Remove plugin directories present on disk but absent from the pack lockfile.
---@param opts? NgPackLockPruneOrphansOpts
---@return string[]|nil removed
---@return string? err
function M.prune_orphans(opts)
  opts = opts or {}

  local names, err = M.list_orphans()
  if names == nil then
    vim.notify(err or "failed", vim.log.levels.ERROR)
    return nil, err
  end

  local selected = {} ---@type table<string, boolean>
  local requested = opts.names or {}
  if #requested == 0 then
    for _, name in ipairs(names) do
      selected[name] = true
    end
  else
    for _, name in ipairs(requested) do
      selected[name] = true
    end
  end

  local removed = {}

  for _, name in ipairs(names) do
    if selected[name] then
      vim.pack.del { name }
      removed[#removed + 1] = name
      selected[name] = nil
    end
  end

  if #removed == 0 then
    if next(selected) ~= nil then
      local missing = vim.tbl_keys(selected)
      table.sort(missing)
      vim.notify(
        ("requested plugins are not currently orphaned on disk: %s"):format(table.concat(missing, ", ")),
        vim.log.levels.WARN
      )
    else
      vim.notify("no orphaned plugin directories to remove", vim.log.levels.INFO)
    end
    return {}
  end

  table.sort(removed)
  vim.notify(
    ("removed %d orphaned plugin director%s: %s"):format(
      #removed,
      #removed == 1 and "y" or "ies",
      table.concat(removed, ", ")
    ),
    vim.log.levels.WARN
  )
  return removed
end

---Remove plugin directories whose installed revisions diverge from the lockfile.
---@param opts? NgPackLockPruneDesyncOpts
---@return string[]|nil removed
---@return string? err
function M.prune_desync(opts)
  opts = opts or {}

  local items, err = collect_desync()
  if items == nil then
    vim.notify(err or "failed", vim.log.levels.ERROR)
    return nil, err
  end

  local selected = {} ---@type table<string, boolean>
  local requested = opts.names or {}
  if #requested == 0 then
    for _, item in ipairs(items) do
      selected[item.name] = true
    end
  else
    for _, name in ipairs(requested) do
      selected[name] = true
    end
  end

  local removed = {}
  for _, item in ipairs(items) do
    if selected[item.name] then
      local ok = delete_pack_data(item.name)
      selected[item.name] = nil
      if ok then
        removed[#removed + 1] = item.name
      end
    end
  end

  if #removed == 0 then
    if next(selected) ~= nil then
      local missing = vim.tbl_keys(selected)
      table.sort(missing)
      vim.notify(
        ("requested plugins are not currently desynced: %s"):format(table.concat(missing, ", ")),
        vim.log.levels.WARN
      )
    else
      vim.notify("no desynced plugin directories to remove", vim.log.levels.INFO)
    end
    return {}
  end

  table.sort(removed)
  vim.notify(
    ("removed %d desynced plugin directories: %s"):format(#removed, table.concat(removed, ", ")),
    vim.log.levels.WARN
  )
  return removed
end

---@return boolean
function M.should_auto_report()
  return vim.env.IN_CONTAINER ~= "1"
end

function M.setup_user_command()
  vim.api.nvim_create_user_command("PackLockDesync", function()
    M.report_desync(true)
  end, {
    desc = "Report desync between nvim-pack-lock.json and installed plugin repositories",
  })

  vim.api.nvim_create_user_command("PackLockDropDesync", function(args)
    M.drop_desync {
      names = args.fargs,
    }
  end, {
    nargs = "*",
    complete = function()
      return M.complete_desync()
    end,
    desc = "Remove desynced lock entries and re-resolve them via vim.pack.add",
  })

  vim.api.nvim_create_user_command("PackLockPruneDesync", function(args)
    M.prune_desync {
      names = args.fargs,
    }
  end, {
    nargs = "*",
    complete = function()
      return M.complete_desync()
    end,
    desc = "Remove plugin directories whose installed revisions diverge from nvim-pack-lock.json",
  })

  vim.api.nvim_create_user_command("PackLockPruneOrphans", function(args)
    M.prune_orphans {
      names = args.fargs,
    }
  end, {
    nargs = "*",
    complete = function()
      return M.list_orphans() or {}
    end,
    desc = "Remove plugin directories on disk that are not present in nvim-pack-lock.json",
  })
end

return M
