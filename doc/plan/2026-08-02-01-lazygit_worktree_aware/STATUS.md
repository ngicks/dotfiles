# Status

Current state: **revision implemented and verified (headless)** — the
2026-08-03 revision (git-delegated detection D9/D10, snacks picker UI D8)
plus the D11 review-fix round are done; the 14-case smoke suite passes with
negative controls. Only the interactive picker-rendering check remains
(cannot be done headless).

## Checklist

Round one (2026-08-02) — done:

- [x] Open questions 1–4, D6 bare-container behavior resolved
- [x] `vim.fs.root`-based implementation + D7 fix round, all headless checks
      passing (see git history for details)

Revision round (2026-08-03):

- [x] Ground git behavior empirically (rev-parse/worktree-list matrix,
      symlink resolution, prunable porcelain marker — PLAN.md Context)
- [x] PLAN.md rewritten around git delegation; D9 recorded; D5 marked
      superseded; D8 stub added
- [x] Resolve open question 1: picker UI → D8, snacks picker global
- [x] Resolve open question 2: marker-less container → D10, per-child probe
- [x] Step 1: git-delegating rework of
      `config/nvim/lua/ngcfg/pkg/terminal/init.lua` (git helper,
      porcelain stanza parsing with bare/prunable filter, D10 per-child
      probe; `canonical`/`is_bare_repo`/`worktrees_under`/`vim.fs.root`
      all removed)
- [x] Step 2: enable snacks picker in
      `github_com--folke--snacks_nvim.lua` (D8)
- [x] Step 3 (headless part): 11-case smoke suite over real git fixtures
      (scratchpad `lazygit_smoke/run.sh`) — 11/11 passing, incl.
      prunable exclusion, marker-less probe, symlinked entry, empty-bare
      warn; negative controls confirm each filter is load-bearing
- [x] Reviewer pass on the revision diff — request-changes: 2 blocking
      (symlinked container children skipped by the `kind` filter;
      locked-then-removed worktrees never marked `prunable` → stale path
      crashes snacks jobstart) + minors (deleted-cwd crash, `.git`-dir
      cwd edge, stale D7 doc text). Recorded as D11; one reviewer clause
      (unrelated repos offered at a plain dir) overruled per D10.
- [x] Fix round per D11 (fs_stat-typed children, candidate existence
      check, deleted-cwd guard) + smoke suite extended to 14 cases —
      all passing; negative controls (fixes reverted in a copy) fail
      exactly the 3 new cases, reproducing the reported crashes
- [ ] Step 3 (interactive part): picker renders as a snacks floating
      picker in a live session (cannot be checked headless)

## Notes

- git 2.55 verified: `--show-toplevel` works from any worktree subdir and
  resolves symlinks; bare container distinguishable via
  `--is-bare-repository`; `prunable`/`bare` stanzas filterable from
  `worktree list --porcelain` alone.
- Known residual from round one (git-absent degradation) is voided by D9:
  git is assumed present.

## Next action

Interactive sanity check in a live session: `<leader>gg` at a bare
container with ≥2 worktrees renders a snacks floating picker (not a noice
message); choosing opens lazygit at the choice; cancelling opens nothing.
