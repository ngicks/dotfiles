# Worktree-aware lazygit toggle

Make `<leader>gg` open lazygit rooted at the worktree root of nvim's
window-local cwd, instead of the raw cwd itself.

**Revision (2026-08-03):** the shipped implementation resolved roots with
`vim.fs.root` + filesystem checks (D5) and showed the worktree picker via the
un-overridden `vim.ui.select` (rendered as a noice message popup). This
revision replaces detection with delegation to git commands (D9) and gives the
picker a real UI (D8).

## Goal / success criteria

- When nvim's window-local cwd is inside a git worktree (linked worktree or
  main checkout), `<leader>gg` opens lazygit with that worktree's root as its
  working directory — even when the cwd is a subdirectory of the worktree.
- Toggling still works: pressing `<leader>gg` again from the same worktree
  hides/shows the same lazygit instance; each worktree gets its own instance.
- When the cwd is a bare-repo container (repo cloned to `.bare`, worktrees as
  subdirectories), `<leader>gg` offers the worktrees via a picker and opens
  lazygit at the chosen one — skipping the prompt when exactly one worktree
  exists.
- The picker renders as a proper selection UI (not the builtin `inputlist()`
  prompt routed through noice's message view).
- All repo-topology questions (root, bareness, worktree enumeration, staleness)
  are answered by shelling out to `git`; no `.git`-marker walking or manual
  path canonicalization. `git` is assumed present (D9).
- When the cwd is outside any git repo, keep today's behavior: lazygit opens
  in nvim's cwd as-is (silent fallback).

## Scope / non-goals

- Scope: `config/nvim/lua/ngcfg/pkg/terminal/init.lua` (detection helpers and
  `M.lazygit`) and
  `config/nvim/lua/ngcfg/plugins/config/github_com--folke--snacks_nvim.lua`
  (enable the snacks picker, D8).
- Non-goal: making the generic terminal toggles (`M.horizontal`, `M.vertical`,
  `M.floating`, `<M-h>/<M-v>/<M-f>`) worktree-aware (D3).
- Non-goal: changing lazygit's own config (`config/lazygit/config.yml`).

## Context

- Mapping: `config/nvim/lua/ngcfg/mappings.lua:100` calls
  `require("ngcfg.pkg.terminal").lazygit()`.
- Current implementation: `config/nvim/lua/ngcfg/pkg/terminal/init.lua` —
  `resolve_git_root` uses `vim.fs.root(cwd, ".git")`, a `worktrees_under`
  child scan for `.git` markers, `vim.uv.fs_realpath` canonicalization, and
  shells out to git only for the bare check and `worktree list`.
- `snacks.terminal` keys instances by `cmd + cwd + env + v:count1`, so passing
  an explicit `cwd` gives one toggleable instance per worktree (D2).
- Picker display problem: nothing in this config overrides `vim.ui.select`,
  so it falls back to the builtin `inputlist()` prompt, which goes through the
  message/cmdline UI that noice manages — rendered as an awkward message
  popup. noice itself does not provide a `vim.ui.select` implementation.
- The installed snacks.nvim ships `snacks.picker` including
  `snacks/picker/select.lua`; when the picker is enabled, its `ui_select`
  option defaults to `true` and replaces `vim.ui.select` globally.
- git behavior, verified empirically with git 2.55 on a bare-container
  fixture (`clone --bare src container/.bare` + `git worktree add`):
  - `git -C <dir> rev-parse --show-toplevel` succeeds from any subdirectory
    of any worktree (main or linked) and prints the worktree root with
    symlinks resolved — entering via a symlinked path still yields the real
    root, so git's output is already canonical for snacks keying (obsoletes
    most of D7's `fs_realpath` plumbing).
  - At a marker-carrying bare container (`.git` file → `gitdir: ./.bare`):
    `--show-toplevel` fails (`fatal: this operation must be run in a work
    tree`) while `rev-parse --is-bare-repository` prints `true`.
  - At a marker-less container and outside any repo: both fail with
    `fatal: not a git repository` (exit 128).
  - `git worktree list --porcelain` prints one stanza per worktree separated
    by blank lines; the container's own entry carries a `bare` line, and
    stale entries carry a `prunable <reason>` line — both filterable from
    porcelain output alone, no `isdirectory` check needed.

## Approach

Delegate the entire decision tree to git, synchronously
(`vim.system(...):wait()` — already how the bare check runs today; latency of
1–2 trivial git calls per keypress is accepted). `git` is assumed installed;
no `pcall`/missing-binary degradation (D9 supersedes that part of D7). The
picker callback structure stays because the picker is asynchronous.

```lua
---@param args string[]
---@return string? # trimmed stdout on exit 0, nil on non-zero exit
local function git(args)
  local res = vim.system(vim.list_extend({ "git" }, args)):wait()
  if res.code ~= 0 then
    return nil
  end
  return vim.trim(res.stdout or "")
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
    local path = stanza:match "^worktree (.-)\n"  -- or whole-stanza match
    -- skip the container's own `bare` entry and stale `prunable` entries
    if path and not stanza:find "\nbare" and not stanza:find "\nprunable" then
      worktrees[#worktrees + 1] = path
    end
  end
  return worktrees
end

---@param cb fun(root: string)
local function resolve_git_root(cb)
  local cwd = vim.fn.getcwd(0)
  if cwd == "" then
    vim.notify("lazygit: cannot determine the working directory", vim.log.levels.WARN)
    return
  end
  local root = git { "-C", cwd, "rev-parse", "--show-toplevel" }
  if root then
    return cb(root) -- any worktree, main or linked, from any subdir
  end
  if git { "-C", cwd, "rev-parse", "--is-bare-repository" } == "true" then
    local candidates = worktree_list(cwd)
    if #candidates == 0 then
      vim.notify("lazygit: bare repository with no worktrees", vim.log.levels.WARN)
      return
    end
    return pick_worktree(candidates, cb)
  end
  -- not a repo at all: marker-less bare container, or genuinely outside git.
  -- git only discovers upward, so probe each child and let git answer (D10).
  local candidates = {}
  for name, kind in vim.fs.dir(cwd) do
    if kind == "directory" then
      local child = vim.fs.joinpath(cwd, name)
      local top = git { "-C", child, "rev-parse", "--show-toplevel" }
      if top == vim.uv.fs_realpath(child) then
        candidates[#candidates + 1] = top
      end
    end
  end
  if #candidates == 0 then
    return cb(cwd) -- D4 silent fallback
  end
  pick_worktree(candidates, cb)
end
```

- Root source stays the window-local cwd (D1); per-worktree instances keyed by
  snacks' `cmd+cwd+env` id (D2); silent cwd fallback outside any repo (D4);
  picker skipped for a single candidate (D6).
- Paths handed to snacks come straight from git (`--show-toplevel`,
  `worktree list --porcelain`), which are already symlink-resolved — the
  `canonical()` helper disappears except (at most) for the non-repo fallback
  cwd.
- Marker-less container: per-child git probe (D10) — `vim.fs.dir` only
  iterates; whether a child is a worktree root is git's answer
  (`--show-toplevel` returning the child itself, compared via
  `fs_realpath(child)` since git's output is symlink-resolved).
- Picker UI (D8): enable the snacks picker globally — add
  `picker = { enabled = true }` to `M.opts` in
  `github_com--folke--snacks_nvim.lua`; snacks then installs
  `vim.ui.select = Snacks.picker.select` (`ui_select` defaults to true), so
  `pick_worktree`'s `vim.ui.select` call — and every other consumer such as
  LSP code actions — renders as a proper floating picker instead of a noice
  message popup. `pick_worktree`'s shape (auto-single, cancel-opens-nothing)
  is unchanged.

Rejected alternatives (this revision):

- `vim.fs.root(cwd, ".git")` + `.git`-marker child scanning + manual
  `fs_realpath` canonicalization (the shipped D5/D7 design) — user directive:
  repo topology is git's domain; lexical/filesystem reimplementation of git
  discovery is exactly what drifts (symlinks, prunable entries, future git
  layouts).
- Async `vim.system` with callbacks — no user-visible benefit for 1–2 fast
  local git calls on an interactive keypress; the sync `:wait()` pattern is
  already in the file.
- `GIT_DISCOVERY_ACROSS_FILESYSTEM` / config tweaks to make git discover the
  marker-less container — git fundamentally discovers upward only; no flag
  makes `rev-parse` look downward.
- Picker alternatives (D8): local `Snacks.picker.select` call (leaves every
  other `vim.ui.select` consumer on the poor builtin rendering), mini.pick
  (third picker style beside telescope/snacks), telescope-ui-select (new
  plugin dependency).
- Marker-less alternatives (D10): first-repo-child `worktree list` (fewer
  spawns but silently picks whichever repo sorts first at a dir of unrelated
  repos), dropping the marker-less case entirely (loses a layout the user
  actually uses).

## Open questions

None — all resolved (see DECISION.md).

## Implementation steps

1. Rework `config/nvim/lua/ngcfg/pkg/terminal/init.lua`: replace
   `canonical`, `is_bare_repo`, `worktree_list`, `worktrees_under`, and
   `resolve_git_root` with the git-delegating versions above (marker-less
   branch = per-child probe, D10). Drop the `pcall`/missing-git guards.
   `M.lazygit` itself is unchanged.
   Verify: `:lcd` into a subdirectory of a linked worktree, `<leader>gg`,
   lazygit shows that worktree's branch/status.
2. Enable the snacks picker (D8): add `picker = { enabled = true }` to
   `M.opts` in
   `config/nvim/lua/ngcfg/plugins/config/github_com--folke--snacks_nvim.lua`.
   Verify interactively: bare container with ≥2 worktrees → picker renders
   as a floating snacks picker, not a noice message; choosing opens lazygit
   at the choice; cancelling opens nothing.
3. Re-run the behavior matrix (headless smoke suite from the first round,
   adjusted to stub `vim.system` git calls instead of `vim.fs.root`):
   main checkout, linked-worktree subdir, marker container, marker-less
   container per-child probe, single-worktree auto-open, cancel, empty bare
   warn, non-repo fallback, symlinked-path instance identity.

## Testing / verification

Manual + headless, against the same fixtures as round one
(`git clone --bare <src> dir/.bare`, `echo "gitdir: ./.bare" > dir/.git`,
`git worktree add`):

- `nvim` at the main checkout → `<leader>gg` → lazygit at main root.
- `:lcd <worktree>/some/subdir` → `<leader>gg` → lazygit at worktree root.
- Toggle: twice in the same worktree = one instance; different worktree cwd =
  separate instance. Entering via a symlinked path toggles the same instance
  (git resolves the path).
- Bare container, 2 worktrees → picker (proper UI); auto-open with 1;
  cancel opens nothing; marker-less variant per Q2.
- Deleted (prunable) worktree absent from candidates — via porcelain
  `prunable` line, not an existence check.
- cwd outside any repo → lazygit at cwd (unchanged).

## Risks

- Multiple simultaneous hidden lazygit instances (one per visited worktree)
  consume a buffer + process each; accepted (D2).
- Every `<leader>gg` now runs 1–2 synchronous git spawns (up from zero for
  plain checkouts in the shipped version); trivial locally, could stutter on
  network filesystems. Accepted per D9.
- If `git` is genuinely absent, the keypress now raises instead of degrading
  (D9 assumes presence); acceptable in this dotfiles environment where git is
  unconditionally installed.
- Bare-container picker reappears on every press (choice not remembered);
  accepted for now, per-tab cache possible later.
