---
name: persistent-memory
description: "Use this skill for storing user preferences and anything the user explicitly asks to remember. Triggers on: 'I prefer', 'I like to', 'always do X', 'remember this', 'remember that I', 'don't do X', 'never do X', 'note that', 'save this preference'. Also use proactively when detecting user preferences during conversation. Consult stored memories at the start of each conversation."
---

# Persistent Memory

Store things the user wants remembered across conversations: preferences (coding style, tools, workflow, communication) and anything they explicitly ask to persist.

**Location:** `.claude/skills/persistent-memory/memories/` (relative to repo root)

## Path Resolution

Commands may run from any subdirectory, and the project may not be a git repo. Always resolve the project root before running commands:

```bash
# Try git first, then walk up looking for .claude/ or AGENTS.md
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  _dir="$PWD"
  while [[ "$_dir" != "/" ]]; do
    [[ -d "$_dir/.claude" || -f "$_dir/AGENTS.md" ]] && break
    _dir="$(dirname "$_dir")"
  done
  REPO_ROOT="$_dir"
}
```

Resolve the skill directory (where this SKILL.md and its scripts live):

```bash
# SKILL_DIR is the directory containing SKILL.md, skim-memories.sh, print-frontmatter.sh
# The agent knows this path from how the skill was loaded — use it directly.
```

Use `$REPO_ROOT` for memory paths and `$SKILL_DIR` for script paths. The skim script resolves both automatically.

## Categories

One directory per category. Default categories as a base:

| Directory        | Purpose                                     |
| ---------------- | ------------------------------------------- |
| `coding-style/`  | Naming, formatting, patterns                |
| `tools/`         | Preferred commands, tools, package managers |
| `workflow/`      | How the user likes to work                  |
| `communication/` | Verbosity, tone, format                     |
| `project/`       | Project-specific conventions                |
| `general/`       | Anything that doesn't fit above             |

Structure freely as needed — create new categories, nest subcategories, or reorganize as the memory grows. The defaults are just a starting point.

### Memory File Format

Each file within a category is a flat bullet-point list with frontmatter containing metadata.

```markdown
---
summary: "How the user prefers to plan and review work"
created: 2026-02-07
updated: 2026-02-07
tag: [planning, review]
parents: []
children: []
---

# Planning Preferences

- Always create a plan before implementing changes
- Prefer small, focused PRs over large ones
- Ask codex to review plans before finalizing
```

**Frontmatter fields:**

| Field      | Required | Description                                                               |
| ---------- | -------- | ------------------------------------------------------------------------- |
| `summary`  | yes      | 1-line description — the decision point for whether to read the full file |
| `created`  | yes      | `YYYY-MM-DD` when the file was first created                              |
| `updated`  | yes      | `YYYY-MM-DD` when the file was last modified                              |
| `tag`      | no       | List of keywords for search and grouping                                  |
| `parents`  | no       | Relative paths to parent memory files this entry relates to               |
| `children` | no       | Relative paths to child memory files                                      |

**Rules:**

- Use `date +%Y-%m-%d` to get the current date.
- Each entry is a single bullet point — concise and actionable.
- Use kebab-case for directory and file names.
- `summary` should contain enough context to decide whether to read the full file.

### Example Structure

```text
memories/
├── coding-style/
│   └── naming.md
├── workflow/
│   ├── planning.md
│   └── pr-process.md
├── tools/
│   └── preferred-tools.md
└── communication/
    └── style.md
```

## Behavior

### At Conversation Start

Skim all memories using the skim script to read summaries and headings first:

```bash
"$SKILL_DIR/skim-memories.sh"
```

If the volume is small (<100 lines total), read all memories in full:

```bash
fd -e md . "$REPO_ROOT/.claude/skills/persistent-memory/memories/" --no-ignore --hidden -x cat {} 2>/dev/null || true
```

### Proactive Detection

Watch for user preferences expressed during conversation and save them without being asked. Examples:

- "I prefer kebab-case" → save to `coding-style/naming.md`
- "Don't add comments to obvious code" → save to `coding-style/comments.md`
- "Keep responses short" → save to `communication/style.md`

### Explicit Requests

Save anything the user explicitly asks to remember:

- "Remember that I prefer X"
- "Note that we use Y for Z"
- "Save this preference"

## Operations

### Save (append bullet)

1. Check for duplicates — scan existing entries before adding
2. Pick the right category directory and file (create if they don't exist)
3. Append the new bullet
4. Update the `updated` date in frontmatter

```bash
# Ensure category directory exists
mkdir -p "$REPO_ROOT/.claude/skills/persistent-memory/memories/coding-style/"

# Check for duplicates
rg "kebab-case" "$REPO_ROOT/.claude/skills/persistent-memory/memories/" --no-ignore --hidden -r 2>/dev/null || true

# Create or append to file within category
# If file doesn't exist, create with frontmatter + heading + bullet
# If file exists, append bullet and update date
```

### Update (replace bullet)

Find the existing entry and replace it. Resolve conflicts by replacing the old entry.

### Remove (delete bullet)

Delete the bullet line from the file. If the file becomes empty (only frontmatter + heading), delete the file. If a category directory becomes empty, remove it.

### List

```bash
fd -e md . "$REPO_ROOT/.claude/skills/persistent-memory/memories/" --no-ignore --hidden -x cat {} 2>/dev/null || true
```

## Search

Memory files are gitignored, so use `--no-ignore --hidden` flags with ripgrep.

### Skim (frontmatter only search)

Use the skim script to see summaries of all memories, showing the first 9 lines of each file:

```bash
# Skim all memories
"$SKILL_DIR/skim-memories.sh"

# Skim only files matching keywords (OR logic)
"$SKILL_DIR/skim-memories.sh" "keyword1" "keyword2"
```

### Full-Text Search

```bash
# Search all content (recursive)
rg "keyword" "$REPO_ROOT/.claude/skills/persistent-memory/memories/" --no-ignore --hidden -i

# List category structure
fd -e md . "$REPO_ROOT/.claude/skills/persistent-memory/memories/" --no-ignore --hidden 2>/dev/null || true
```

## Guidelines

1. **No duplicates** — scan existing entries before adding
2. **Resolve conflicts** — replace the old entry with the new one
3. **Include rationale when given** — "Prefers X because Y"
4. **Keep entries concise** — one bullet per preference, actionable and clear
5. **Don't over-categorize** — use existing categories before creating new ones
