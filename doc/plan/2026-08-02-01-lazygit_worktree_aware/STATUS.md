# Status

Current state: **revision planned, ready to implement** — round-one
implementation shipped and verified; the 2026-08-03 revision (git-delegated
detection D9/D10, snacks picker UI D8) is fully decided with no open
questions. Next: implementation steps 1–3.

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
- [ ] Step 1: git-delegating rework of
      `config/nvim/lua/ngcfg/pkg/terminal/init.lua`
- [ ] Step 2: enable snacks picker in
      `github_com--folke--snacks_nvim.lua` (D8)
- [ ] Step 3: re-run behavior matrix (headless smoke + interactive picker
      check)

## Notes

- git 2.55 verified: `--show-toplevel` works from any worktree subdir and
  resolves symlinks; bare container distinguishable via
  `--is-bare-repository`; `prunable`/`bare` stanzas filterable from
  `worktree list --porcelain` alone.
- Known residual from round one (git-absent degradation) is voided by D9:
  git is assumed present.

## Next action

Implement steps 1–3 (PLAN.md).
