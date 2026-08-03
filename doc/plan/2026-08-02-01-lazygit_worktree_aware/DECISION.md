# Decisions

## D11: Revision-review amendments — symlinked children, locked-worktree staleness, deleted cwd (resolved 2026-08-03)

Amendments from the reviewer pass on the D9/D10 implementation:

- **Symlinked container children (blocking, regression):** `vim.fs.dir`
  reports a symlink-to-directory as kind `"link"`, so the per-child probe's
  `kind == "directory"` filter silently skipped symlinked worktrees that the
  pre-revision `worktrees_under` (symlink-following `fs_stat`) handled. Fix:
  type children via `vim.uv.fs_stat(child)` (follows symlinks), then probe.
- **Locked-worktree staleness (blocking):** git deliberately exempts locked
  worktrees from `prunable` marking — a locked worktree whose directory was
  removed shows a `locked` line and **no** `prunable` line, falsifying D9's
  claim that porcelain `prunable` fully replaces the existence check. A stale
  path reaching snacks crashes its unwrapped `jobstart` (E475). Fix: keep the
  `bare`/`prunable` stanza filter and additionally drop candidates failing
  `vim.uv.fs_stat`. This is a filesystem existence check, not lexical path
  manipulation — git refuses to answer this particular question.
- **Deleted window cwd (minor):** the inherited `getcwd(0) == ""` guard is
  dead code — after the cwd is deleted, `getcwd(0)` keeps returning the last
  valid path, every git call fails (git must chdir), and resolution fell
  through to opening lazygit at the nonexistent path (E475). Fix: replace the
  empty-string guard with an `fs_stat` existence check on the cwd; warn and
  abort when gone. (The old `vim.fs.root` upward walk recovered here; the
  git-delegated chain cannot, so abort-with-warning is the honest behavior.)

Accepted without fix (documented edges):

- cwd deliberately placed inside a plain repo's `.git` directory resolves to
  `.git` itself (pre-revision code found the repo root via the upward walk);
  requires a deliberate `:lcd` there — nothing in this config auto-chdirs.
- At a plain directory of unrelated repos, the per-child probe offers them
  all in the picker — the shipped semantics D10 deliberately preserves, not
  a defect (the reviewer flagged it; overruled by D10).

## D9: Detection delegated to git commands (resolved 2026-08-03, supersedes D5)

User directive: assume `git` is present and delegate repo-topology questions
to it instead of lexical/filesystem manipulation. Concretely:

- Root: `git -C <cwd> rev-parse --show-toplevel` (succeeds from any subdir of
  any worktree, output symlink-resolved) replaces `vim.fs.root(cwd, ".git")`.
- Bareness: `git -C <cwd> rev-parse --is-bare-repository` when toplevel fails.
- Staleness: `prunable` lines in `git worktree list --porcelain` stanzas
  replace the `isdirectory` existence check. (Amended by D11: locked
  worktrees are exempt from `prunable` marking, so an `fs_stat` existence
  check on candidates is retained on top of the stanza filter.)
- Canonicalization: git's own symlink-resolved output replaces the
  `fs_realpath`-based `canonical()` helper (obsoletes that part of D7).
- The `pcall`/missing-git degradation guards from D7 are dropped; git absent
  ⇒ loud error is acceptable.

Calls stay synchronous (`vim.system():wait()`), as the bare check already was.

Superseded: D5 (`vim.fs.root` chosen to avoid a subprocess — rationale was
weak given the code already spawned git synchronously for the bare check).

## D8: Worktree picker UI — snacks picker, enabled globally (resolved 2026-08-03)

`vim.ui.select` had no real implementation in this config; the builtin
`inputlist()` fallback renders through noice's message/cmdline view and
displays poorly (noice does not itself provide a select UI). Fix: add
`picker = { enabled = true }` to `M.opts` in
`config/nvim/lua/ngcfg/plugins/config/github_com--folke--snacks_nvim.lua` —
snacks then installs `vim.ui.select = Snacks.picker.select` (`ui_select`
defaults to true), so the worktree picker and every other `vim.ui.select`
consumer (LSP code actions, etc.) get a proper floating picker.
`pick_worktree` keeps calling `vim.ui.select` unchanged.

Rejected:
- Local `Snacks.picker.select` call in `pick_worktree` — leaves all other
  `vim.ui.select` consumers on the poor builtin rendering.
- mini.pick `ui_select` — adds a third picker style beside telescope/snacks.
- telescope-ui-select — new plugin dependency, heaviest option.

## D10: Marker-less bare container — per-child git probe (resolved 2026-08-03)

With detection delegated to git (D9), the marker-less container (no
`gitdir: ./.bare` file) is invisible to `git -C <cwd>` since git only
discovers upward. Chosen: iterate child directories with `vim.fs.dir` and
accept a child as a candidate when `git -C <child> rev-parse --show-toplevel`
returns the child itself (compared against `fs_realpath(child)` since git's
output is symlink-resolved); no candidates → D4 silent fallback. Preserves the
shipped semantics; the only local logic is directory iteration — worktree-ness
is git's answer per child. Cost: one git spawn per child dir per press in this
case, accepted.

Rejected:
- First-repo-child `worktree list` answers for all — fewer spawns and finds
  worktrees living elsewhere, but at a dir of unrelated repos it silently
  picks whichever repo sorts first.
- Dropping marker-less support (require the marker file) — loses a layout the
  user actually uses.

## D1: Root detection source — window-local cwd (resolved 2026-08-02)

Resolve `vim.fn.getcwd(0)` upward to its worktree root via
`vim.fs.root(cwd, ".git")`. The user chose this over the recommended
buffer-file basis: the root stays predictable regardless of which buffer is
focused (e.g. files from other worktrees opened via go-to-definition don't
retarget lazygit).

Rejected: current buffer's file as the root source.

## D2: Instance model — one per worktree (resolved 2026-08-02)

One lazygit instance per worktree, keyed naturally by snacks.terminal's
`cmd+cwd+env` id. Zero extra code; hidden instances costing a buffer +
process each is acceptable.

Rejected: single global instance killed/reopened on worktree change — extra
code to locate and close the old terminal, and loses lazygit UI state.

## D3: Scope — lazygit only (resolved 2026-08-02)

Only `<leader>gg` becomes worktree-aware. `<M-h>/<M-v>/<M-f>` shell toggles
keep starting at nvim's cwd.

Rejected: applying root detection to all terminal toggles.

## D4: No-repo behavior — silent fallback (resolved 2026-08-02)

When the cwd is not under any git repo, open lazygit at the cwd as-is,
matching today's behavior.

Rejected: `vim.notify` warning and skipping the open.

## D7: Review amendments — canonical paths, warn on empty bare, degrade gracefully (resolved 2026-08-02; partially superseded by D9)

Amendments from the post-implementation review:

- All roots and candidates are canonicalized via `vim.uv.fs_realpath`
  (falling back to `vim.fs.normalize`) so symlinked paths cannot split one
  worktree across two snacks terminal ids (D2 would otherwise silently
  break in the marker-less container branch).
- A confirmed-bare root with **zero** worktrees warns via `vim.notify` and
  opens nothing, instead of reusing D4's silent fallback — the fallback
  target would be the bare dir itself, i.e. the degraded mode D6 exists to
  avoid. D4's silent cwd fallback remains only for the genuine not-a-repo
  case.
- `prunable` (stale) worktree entries are dropped by an existence check on
  the candidate path.
- Deleted cwd (`getcwd` → `""`) warns and aborts; a missing `git` binary is
  caught with `pcall` and degrades to not-bare / no candidates instead of a
  raw Lua error. (Both superseded: the `pcall` guards are removed by D9 —
  git absent now raises; and the `getcwd == ""` premise is empirically false
  — D11 replaces it with an `fs_stat` existence check.)
- Accepted and documented: linked worktrees (`.git` file) run one cheap
  synchronous `git rev-parse --is-bare-repository` per press; only plain
  top-level checkouts (`.git` directory) short-circuit it.

## D6: Bare-repo container — worktree picker, auto if single (resolved 2026-08-02)

When the cwd resolves to a bare-repo container (repo cloned to `.bare`,
worktrees as subdirectories), offer the worktrees via `vim.ui.select` and
open lazygit at the chosen one; skip the prompt when exactly one worktree
exists. Detection: resolved root is bare per
`git rev-parse --is-bare-repository` (container has a `.git` marker file),
or no root found but immediate children carry `.git` markers (no marker
file). Cancelling the picker opens nothing.

Rejected:
- Plain picker without the single-worktree shortcut — needless prompt in the
  common one-worktree case.
- Buffer-file rescue (use the current buffer's worktree in this case only) —
  reintroduces the focus-dependence D1 rejected.
- Out of scope / keep silent fallback — leaves `<leader>gg` useless (or
  prompting to init a new repo) in a layout the user actually uses.

## D5: Detection mechanism — `vim.fs.root` over `git rev-parse` (SUPERSEDED by D9)

Chose `vim.fs.root(cwd, ".git")` — synchronous, no subprocess, and matches
the `.git` *file* that marks a linked worktree root. Rejected
`git rev-parse --show-toplevel` (subprocess + async plumbing) and `:lcd`
tricks (window state side effects).
