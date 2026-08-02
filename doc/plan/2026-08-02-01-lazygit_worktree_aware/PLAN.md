# Worktree-aware lazygit toggle

Make `<leader>gg` open lazygit rooted at the worktree root of nvim's
window-local cwd, instead of the raw cwd itself.

## Goal / success criteria

- When nvim's window-local cwd is inside a git worktree (linked worktree or
  main checkout), `<leader>gg` opens lazygit with that worktree's root as its
  working directory — even when the cwd is a subdirectory of the worktree.
- Toggling still works: pressing `<leader>gg` again from the same worktree
  hides/shows the same lazygit instance; each worktree gets its own instance.
- When the cwd is a bare-repo container (repo cloned to `.bare`, worktrees as
  subdirectories), `<leader>gg` offers the worktrees via `vim.ui.select` and
  opens lazygit at the chosen one — skipping the prompt when exactly one
  worktree exists.
- When the cwd is outside any git repo, keep today's behavior: lazygit opens
  in nvim's cwd as-is (silent fallback).

## Scope / non-goals

- Scope: `M.lazygit()` in `config/nvim/lua/ngcfg/pkg/terminal/init.lua` and,
  only if needed, the mapping in `config/nvim/lua/ngcfg/mappings.lua:100`.
- Non-goal: making the generic terminal toggles (`M.horizontal`, `M.vertical`,
  `M.floating`, `<M-h>/<M-v>/<M-f>`) worktree-aware (open question 3).
- Non-goal: changing lazygit's own config (`config/lazygit/config.yml`).

## Context

- Mapping: `config/nvim/lua/ngcfg/mappings.lua:100`
  ```lua
  map("n", "<leader>gg", function()
    require("ngcfg.pkg.terminal").lazygit()
  end, { noremap = true, silent = true, desc = "Toggle lazygit floating window" })
  ```
- Implementation: `config/nvim/lua/ngcfg/pkg/terminal/init.lua:37` calls
  `require "snacks.lazygit" { win = { ... } }` with no `cwd`.
- `snacks.lazygit.open()` forwards opts to `Snacks.terminal(cmd, opts)`.
  `snacks.terminal` defaults `opts.cwd` to `vim.fn.getcwd(0)` (window-local
  cwd) and derives the terminal instance id from `cmd + cwd + env + v:count1`.
  Therefore passing an explicit `cwd` both roots lazygit correctly **and**
  gives one toggleable instance per worktree for free.
- Worktree detection: in a linked worktree the root contains a `.git` *file*
  (not directory). `vim.fs.root(buf, ".git")` matches both file and directory,
  so it returns the worktree root (not the common gitdir). Available since
  nvim 0.10; this config runs on nvim 0.12 (native `vim.pack`, plugins under
  `site/pack/core/opt/`).
- lazygit itself handles being started inside a linked worktree fine; nothing
  extra is needed beyond the correct `cwd`.
- Bare-container layout (verified empirically): with the repo cloned to
  `<dir>/.bare` and worktrees as subdirectories of `<dir>`,
  - without a `.git` marker file at `<dir>`, `vim.fs.root` finds nothing
    (it only walks **up**; `.bare` doesn't match the `.git` marker name) —
    naive fallback would land lazygit in a non-repo dir where it prompts to
    init a new repository;
  - with the conventional `.git` file (`gitdir: ./.bare`), `vim.fs.root`
    returns `<dir>`, but there `git rev-parse --is-bare-repository` is
    `true` and `git status` fails with `fatal: this operation must be run in
    a work tree` — lazygit would open in degraded bare mode at best.
  - In both variants `git worktree list --porcelain` (run via `-C` against
    the bare dir or any worktree) lists all worktrees, giving the picker its
    candidates.

## Approach

Resolve the window-local cwd upward to its worktree root; when that root is
a bare-repo container, resolve *downward* via a worktree picker. Because
`vim.ui.select` is asynchronous, root resolution passes the result to a
callback that opens lazygit:

```lua
---@param cb fun(root: string)
local function resolve_git_root(cb)
  local cwd = vim.fn.getcwd(0)
  local root = vim.fs.root(cwd, ".git")
  if root == nil then
    -- setup A: container without a `.git` marker file. Look for worktrees
    -- one level down; no candidates means "not a repo" -> D4 fallback.
    local candidates = worktrees_under(cwd) -- children with a `.git` marker
    return pick_worktree(candidates, cwd, cb)
  end
  if is_bare(root) then -- `git -C root rev-parse --is-bare-repository`
    -- setup B: `.git` file pointing at `.bare`
    return pick_worktree(worktree_list(root), root, cb)
  end
  cb(root)
end

local function pick_worktree(candidates, fallback, cb)
  if #candidates == 0 then return cb(fallback) end     -- D4
  if #candidates == 1 then return cb(candidates[1]) end -- auto if single
  vim.ui.select(candidates, { prompt = "lazygit worktree" }, function(choice)
    if choice then cb(choice) end -- cancelled -> do not open
  end)
end

function M.lazygit()
  resolve_git_root(function(root)
    require "snacks.lazygit" { cwd = root, win = { ...existing... } }
  end)
end
```

- Root source is the window-local cwd, not the current buffer's file:
  stable regardless of which buffer happens to be focused (decision D1).
- One lazygit instance per worktree, keyed naturally by snacks.terminal's
  `cmd+cwd+env` id (decision D2). This also holds across picker choices:
  picking worktree A then later worktree B yields two independent toggles.
- Bare-container case: worktree candidates come from
  `git -C <root> worktree list --porcelain` (bare entry filtered out) when a
  bare root was found, or from scanning immediate children for a `.git`
  marker when no root was found at all (setup A). Picker skipped when
  exactly one candidate exists (decision D6).
- Only `<leader>gg` changes; `<M-h>/<M-v>/<M-f>` stay at nvim cwd (D3).
- Outside a git repo (and no worktree children), fall back to the cwd
  silently (D4).
- Review amendments (D7): all roots/candidates canonicalized via
  `vim.uv.fs_realpath` so symlinks can't split a worktree across two snacks
  ids; a confirmed-bare root with zero worktrees warns and opens nothing
  (D4's silent fallback would land in the bare dir); stale `prunable`
  worktree entries filtered by an existence check; deleted cwd and missing
  `git` binary degrade gracefully instead of raising.

Rejected alternatives:

- Basing detection on the current buffer's file — jumps roots when focusing
  buffers from other worktrees (e.g. via LSP go-to-definition); user prefers
  the cwd-anchored, predictable root.
- `git rev-parse --show-toplevel` via `vim.system` — an extra subprocess and
  async plumbing for what `vim.fs.root` answers synchronously from the
  filesystem.
- Changing nvim's cwd (`:lcd`) before opening — side effects on the window
  outlive the lazygit toggle.
- Configuring it via `M.opts.lazygit` in
  `config/nvim/lua/ngcfg/plugins/config/github_com--folke--snacks_nvim.lua` —
  `cwd` must be computed per invocation, not once at setup.
- Single global instance killed/reopened on worktree change — extra code and
  loses lazygit UI state; per-worktree instances come for free.

## Implementation steps

1. Edit `config/nvim/lua/ngcfg/pkg/terminal/init.lua`: add the local helpers
   (`resolve_git_root`, `pick_worktree`, `worktree_list`, bare check) and
   rework `M.lazygit` to open via the resolution callback, passing `cwd`
   alongside the existing `win` opts.
   Verify: `:lcd` into a subdirectory of a linked worktree, `<leader>gg`,
   lazygit shows that worktree's branch/status.
2. Verify toggling: `<leader>gg` twice in the same worktree hides/shows one
   instance; a window whose cwd is another worktree gets a separate instance
   rooted there.
3. Verify the bare-container case: nvim started at a `<dir>` holding `.bare`
   plus ≥2 worktrees shows the `vim.ui.select` picker (both with and without
   the `.git` marker file at `<dir>`); with exactly one worktree it opens
   directly; cancelling the picker opens nothing.
4. Verify fallback: with cwd outside any git repo, `<leader>gg` behaves as
   today (lazygit at nvim cwd).

## Testing / verification

Manual, inside a repo with a linked worktree (`git worktree add`), plus a
bare-container fixture (`git clone --bare <src> dir/.bare && cd dir &&
echo "gitdir: ./.bare" > .git && git worktree add wt1 && ...`):

- `nvim` with cwd at the main checkout → `<leader>gg` → lazygit at main root.
- `:lcd <worktree>/some/subdir` → `<leader>gg` → lazygit at worktree root.
- Toggle behavior per step 2 above.
- Bare container, 2 worktrees → picker; choose one → lazygit rooted there;
  `<leader>gg` again from the same cwd re-prompts but toggles the existing
  instance when the same worktree is chosen.
- Bare container, 1 worktree → opens directly, no prompt.
- cwd outside any repo → `<leader>gg` → lazygit at cwd (unchanged).

## Risks

- Multiple simultaneous hidden lazygit instances (one per visited worktree)
  consume a buffer + process each; accepted in decision D2.
- The bare check shells out to `git` synchronously on keypress whenever the
  resolved root's `.git` is not a directory — i.e. also for linked
  worktrees, the feature's primary scenario, not just bare containers. The
  command is trivial, so latency is accepted; only plain top-level
  checkouts short-circuit it.
- In the bare-container case the picker reappears on every `<leader>gg`
  (including to hide an already-open instance) since the choice is not
  remembered; accepted for now — a per-tab cache can be added later if it
  becomes annoying.
