# Status

Current state: **done** — implemented, reviewed, D7 fix round applied,
all headless checks passing.

## Checklist

- [x] Resolve open questions 1–4 (PLAN.md)
- [x] Resolve bare-repo container behavior (D6: picker, auto if single)
- [x] Step 1: root resolution helpers + `cwd` in `M.lazygit`
      (`config/nvim/lua/ngcfg/pkg/terminal/init.lua`)
- [x] Step 2: verify per-worktree toggle behavior — headless nvim with
      real snacks: second `lazygit()` call at the same cwd toggled the
      existing instance (one buffer), cwd passed through correctly
- [x] Step 3: verify bare-container picker / auto-single / cancel —
      headless smoke test over /tmp/wtfix fixtures (marker + no-marker
      containers, single-worktree auto-open, cancel opens nothing)
- [x] Step 4: verify no-repo cwd fallback — smoke test
- [x] Reviewer pass (ng-reviewer) — request-changes: 2 blocking
      (symlink canonicalization; empty bare container falls into
      degraded bare mode) + 3 minor (prunable entries, raw errors on
      deleted cwd / missing git, overstated fast-path comment)
- [x] Fix round per D7 (canonical paths, warn on empty bare, prunable
      filter, empty-cwd / missing-git guards, comment fix)
- [x] Re-run after fixes — 15-case stubbed smoke suite plus the
      real-snacks toggle check, all passing

## Notes

- Verification was headless; a quick interactive sanity check of the
  `vim.ui.select` picker in a live session is still a nice-to-have.
- Known residual (accepted): if `git` is absent from PATH, the bare
  check degrades to "not bare" and a marker-carrying bare container
  opens at the bare root without a warning — indistinguishable from a
  genuine non-bare answer without widening the contract.

## Next action

None — complete. Optional: interactive picker sanity check in a live
session.
