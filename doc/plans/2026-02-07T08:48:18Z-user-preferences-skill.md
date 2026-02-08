# Plan: Create `persistent-memory` Skill

## Context

We need a skill for storing things the user wants remembered across conversations: preferences (coding style, tools, workflow, communication) and anything they explicitly ask to persist.

## Changes

### 1. Create `agents/skills/persistent-memory/SKILL.md`

Skill file following discovery convention (`agents/skills/*/SKILL.md`).

**Frontmatter:**
- `name: persistent-memory`
- `description`: trigger phrases (`I prefer`, `I like to`, `always do X`, `remember this`, `remember that I`, `don't do X`, `note that`, `save this preference`) + proactive detection of user preferences + consult at conversation start

**Storage:** `.claude/skills/persistent-memory/memories/` (gitignored via `.claude/`)

**Format:** One file per category, flat bullet-point list, minimal frontmatter.

Default categories:
- `coding-style.md` — naming, formatting, patterns
- `tools.md` — preferred commands, tools, package managers
- `workflow.md` — how the user likes to work
- `communication.md` — verbosity, tone, format
- `project.md` — project-specific conventions
- `general.md` — anything that doesn't fit above

Create new categories only when existing ones don't fit.

Example category file:
```markdown
---
updated: 2026-02-07
---

# Workflow

- Always create a plan before implementing changes
- Prefer small, focused PRs over large ones
- Ask codex to review plans before finalizing
```

**Key behaviors:**
- Read ALL memories at conversation start — expected <100 lines total, full read is cheap
- Use `--no-ignore --hidden` flags with ripgrep when searching (`.claude/` is gitignored)
- Date format: `YYYY-MM-DD`. `updated` field is required.
- Proactively detect user preferences and save them
- Save anything the user explicitly asks to remember

**Operations:** Save (append bullet), Update (replace bullet), Remove (delete bullet), List (`cat *.md`)

**Guidelines:**
- No duplicates — scan existing entries before adding
- Resolve conflicts by replacing the old entry
- Include rationale when given: "Prefers X because Y"
- Keep entries concise and actionable

### 2. Update `agents/AGENTS.md` — `## Important` section

Replace the line:
```
- Remenber to use the agent-memory skill the moment user's preference become prominent.
```

With:
```
- Use the **persistent-memory** skill for user preferences and anything the user explicitly asks to remember. Consult stored memories at the start of each conversation.
```

### 3. Update `CLAUDE.md` — `## Important` section

Same replacement as above — these two files share the same `## Important` section.

## Files to Modify

| File | Action | What |
|------|--------|------|
| `agents/skills/persistent-memory/SKILL.md` | create | New skill definition |
| `agents/AGENTS.md` | edit | Update memory guidance in `## Important` |
| `CLAUDE.md` | edit | Same update in `## Important` |

## Design Rationale

- **Flat bullet-point format**: memories are short statements, not structured documents
- **Category files**: organized but small enough to `cat *.md` in full
- **No tags/status fields**: entries are current or removed — no lifecycle tracking needed
- **Read-all at start**: safe because total volume stays small; avoids missing applicable preferences

## Verification

1. Confirm `agents/skills/persistent-memory/SKILL.md` exists with correct frontmatter
2. Start a new Claude Code session — confirm the skill appears in system-reminder skill list
3. Test save: say "remember I prefer kebab-case for file names", verify file at `.claude/skills/persistent-memory/memories/coding-style.md`
4. Test recall: start another session, verify agent reads stored memories
5. Confirm `agents/AGENTS.md` and `CLAUDE.md` both have updated guidance
