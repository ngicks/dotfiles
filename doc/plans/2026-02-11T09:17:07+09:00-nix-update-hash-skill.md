# Create `nix-update-hash` Skill

## Context

The script `scripts/homeenv/nix-update-hash.sh` already exists and provides two subcommands:
- `vendor <path-to-nix-pkg-file>` — Computes the correct `vendorHash` for a Go `buildGoModule` package by building with `fakeHash` and extracting the real hash from the error output
- `github <owner> <repo> <rev>` — Prefetches a GitHub flake and returns its hash via `nix flake prefetch`

This script is useful during Nix package development but isn't exposed as a Claude Code skill yet. The user wants it copied into a skill directory so Claude can invoke it when updating Nix package hashes.

## Plan

### 1. Create skill directory and copy the script

- Create `.claude/skills/nix-update-hash/`
- Copy `scripts/homeenv/nix-update-hash.sh` → `.claude/skills/nix-update-hash/nix-update-hash.sh`

### 2. Create `SKILL.md`

**File:** `.claude/skills/nix-update-hash/SKILL.md`

Following the pattern of existing skills (frontmatter with `name` + `description`, then documentation).

### 3. Write plan to `doc/plans/`

## Files Created

| File | Action |
|------|--------|
| `.claude/skills/nix-update-hash/SKILL.md` | Created — skill definition |
| `.claude/skills/nix-update-hash/nix-update-hash.sh` | Copied from `scripts/homeenv/nix-update-hash.sh` |
| `doc/plans/2026-02-11T09:17:07+09:00-nix-update-hash-skill.md` | Created — plan doc |

## Status

Implemented.
