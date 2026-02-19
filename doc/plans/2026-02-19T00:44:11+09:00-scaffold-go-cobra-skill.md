# Skill: scaffold-go-cobra

## Context

Need a Claude Code skill to scaffold new Go CLI projects with Cobra subcommands. The skill should follow the exact patterns established in `tools/lsp-gw/` — same main.go signal setup, same cmd/ structure, same naming conventions.

## Design

Single file: `.claude/skills/scaffold-go-cobra/SKILL.md` (no helper scripts needed — Claude generates files directly via Write tool).

### Behavior

1. **Interview** the user for: project name, output directory, Go module path, subcommands + descriptions
2. **Generate** files following lsp-gw patterns
3. **Run** `go mod tidy` to resolve deps

### Generated Files

| File | Content |
|------|---------|
| `main.go` | Signal setup + `cmd.NewRootCmd().ExecuteContext(ctx)` |
| `cmd/root.go` | `NewRootCmd()` with SilenceUsage/SilenceErrors, wires subcommands |
| `cmd/<subcmd>.go` | One per subcommand, `newXxxCmd()` with TODO body |
| `go.mod` | Module path + cobra v1.10.2 + go 1.24.0 |

### Conventions (from lsp-gw)

- `NewRootCmd()` exported, `newXxxCmd()` unexported
- Always `RunE` (not `Run`)
- `SilenceUsage: true`, `SilenceErrors: true` on root
- Root RunE returns `cmd.Help()`
- `cobra.NoArgs` default
- One file per subcommand, filename matches command name
- Hyphenated names: `db-migrate` → file `cmd/db-migrate.go`, func `newDbMigrateCmd()`

## Verification

1. Invoke skill: "scaffold go mytool with serve and migrate"
2. Verify files created at target directory
3. `cd <dir> && go build .` should compile
4. `./<name> --help` shows cobra help with subcommands
