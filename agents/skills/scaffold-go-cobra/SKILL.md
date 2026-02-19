---
name: scaffold-go-cobra
description: "Scaffold a Go CLI project with Cobra subcommands following tools/ conventions. Triggers on: 'scaffold go', 'new go cli', 'cobra project', 'create go command', 'new go tool'."
---

# Scaffold Go Cobra CLI

Generate a Go CLI project with Cobra subcommands.

## Interview

Before generating files, gather the following from the user. If provided inline (e.g. "scaffold go mytool with serve and migrate"), extract values directly — only ask for missing required fields.

| Parameter         | Required | Default                    | Example                    |
| ----------------- | -------- | -------------------------- | -------------------------- |
| Project name      | yes      | -                          | `mytool`                   |
| Output directory  | yes      | -                          | `tools/mytool`             |
| Go module path    | no       | `github.com/watage/<name>` | `github.com/watage/mytool` |
| Short description | no       | `<name> CLI tool.`         | `My awesome tool.`         |
| Subcommands       | no       | _(none)_                   | `serve`, `migrate`         |

Subcommands can be nested using **dot notation** (`server.start`, `server.stop`) or natural language ("a server group containing start and stop"). When a dotted subcommand is given, the part before the dot becomes a parent group command and the part after becomes a child leaf command.

For each subcommand, ask for a short description if not provided. Default to `<Name> subcommand.`.

## Templates

### `main.go`

```go
package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"syscall"

	"github.com/ngicks/go-common/contextkey"
	"{{MODULE}}/commands"
)

func main() {
    logger := slog.New(
		slog.NewJSONHandler(
			os.Stdout,
			&slog.HandlerOptions{
				AddSource: true,
				Level:     slog.LevelDebug,
			},
		),
	)

	ctx, stop := signal.NotifyContext(
		context.Background(),
		syscall.SIGINT,
		syscall.SIGTERM,
	)
	defer stop()


    ctx = contextkey.WithSlogLogger(ctx, logger)

	if err := commands.Execute(ctx); err != nil {
        logger.ErrorContext(ctx, "stopped with an error", slog.Any("err", err))
		os.Exit(1)
	}
}
```

### `commands/root.go`

```go
package commands

import (
	"context"
	"log/slog"

	"github.com/spf13/cobra"
)

func Execute(ctx context.Context) error {
    return rootCmd.ExecuteContext(ctx)
}

var rootCmd = &cobra.Command{
		Use:           "{{NAME}}",
		Short:         "{{SHORT_DESCRIPTION}}",
		SilenceUsage:  true,
		SilenceErrors: true,
		Args:          cobra.NoArgs,
		RunE: runRoot,
}

var (
   flagA = rootCmd.PersistentFlags().String("name", "default value", "description of opton")
   flagB = rootCmd.PersistentFlags().String(...)
)

func runRoot(cmd *cobra.Command, args []string) error {
    return cmd.Help()
}
```

### `commands/<parent>.go` (parent group command — no `RunE`)

When a subcommand has children (e.g. `server.start`), the parent is a grouping command with no run logic. Cobra shows help by default.

```go
package commands

import "github.com/spf13/cobra"

func init() {
	rootCmd.AddCommand({{parentCamel}}Cmd)
}

var {{parentCamel}}Cmd = &cobra.Command{
    Use:   "{{parent-name}}",
    Short: "{{Parent short description}}",
}
```

### `commands/{{parent}}_{{child}}.go` (child leaf command, wired to parent)

```go
package commands

import (
	"fmt"

	"github.com/spf13/cobra"
)

func init() {
	{{parentCamel}}Cmd.AddCommand({{parentCamel}}{{ChildPascal}}Cmd)
}

var {{parentCamel}}{{ChildPascal}}Cmd = &cobra.Command{
    Use:   "{{child-name}}",
    Short: "{{Child short description}}",
    Args:  cobra.NoArgs,
    RunE:  run{{ParentPascal}}{{ChildPascal}},
}

func run{{ParentPascal}}{{ChildPascal}}(cmd *cobra.Command, args []string) error {
    fmt.Println("TODO: implement {{parent-name}} {{child-name}}")
    return nil
}
```

Key differences from flat subcommands:

- Parent command has **no `RunE`/`Args`** — it's just a group (shows help by default)
- Child file name uses **underscore** to join levels: `commands/server_start.go`
- Child var name concatenates: `serverStartCmd`
- Child `init()` wires to **parent var**, not `rootCmd`
- 3rd level follows the same pattern: `commands/server_start_foo.go`, wired to `serverStartCmd`

### `go.mod`

```
module {{MODULE}}

go 1.26.0

require (
    github.com/ngicks/go-common/contextkey v0.2.0
    github.com/spf13/cobra v1.10.2
)
```

## Naming Conventions

### Flat subcommands

- **Command vars**: `{{camelCase}}Cmd` — package-level `var` of `*cobra.Command`. Examples:
  - `serve` -> `serveCmd`
  - `dry-run` -> `dryRunCmd`
  - `db-migrate` -> `dbMigrateCmd`
- **Run functions**: `run{{CamelCase}}` — separate named function, not inline closure. Examples:
  - `serve` -> `runServe`
  - `dry-run` -> `runDryRun`
  - `db-migrate` -> `runDbMigrate`
- **Wiring**: each subcommand file uses `init()` to call `rootCmd.AddCommand(xxxCmd)`
- **File names**: `commands/<subcmd>.go` using the exact subcommand name (e.g. `commands/serve.go`, `commands/dry-run.go`)

### Nested subcommands

- **File names**: `commands/{{parent}}_{{child}}.go` — underscore-joined, preserving hyphens within each segment. Examples:
  - `server start` -> `commands/server_start.go`
  - `db dry-run` -> `commands/db_dry-run.go`
  - `db migrate up` (3 levels) -> `commands/db_migrate_up.go`
- **Var names**: concatenate camelCase segments. Examples:
  - `server` + `start` -> `serverStartCmd`
  - `db` + `migrate` + `up` -> `dbMigrateUpCmd`
- **Run functions**: concatenate PascalCase segments. Examples:
  - `server start` -> `runServerStart`
  - `db migrate up` -> `runDbMigrateUp`
- **Parent commands**: no `RunE`, no `Args` — cobra shows help by default
- **Wiring**: child `init()` calls `{{parentCamel}}Cmd.AddCommand(...)`, not `rootCmd`

### General rules

- **Always use `RunE`**, never `Run` — return errors instead of calling `os.Exit`
- **Default `Args`**: `cobra.NoArgs` unless the user specifies arguments
- **Root command**: package-level `var rootCmd`, delegates to `runRoot` which calls `cmd.Help()`
- **SilenceUsage + SilenceErrors**: always set on root command
- **Flags**: package-level `var` block using `rootCmd.PersistentFlags()` or `xxxCmd.Flags()` in a separate `init()`

## Generation Steps

1. Resolve all parameters (interview or extract from user message)
2. Create output directory and `commands/` subdirectory
3. Write `go.mod` using the Write tool
4. Write `main.go` using the Write tool
5. Write `commands/root.go` with `rootCmd` var and `Execute` function
6. Write one `commands/<subcmd>.go` per subcommand (each with its own `init()` for `AddCommand` wiring)
7. For nested commands, generate **parent files before child files** (children reference parent vars via `init()`)
8. Run `cd <output-dir> && go mod tidy` to resolve dependencies
9. Report the generated file list to the user

## Important

- Generate files using the **Write** tool — do not use helper scripts
- Keep generated code minimal — no extra helpers, no unused imports
- If the user provides flags, add them as a separate `init()` block in the subcommand file (persistent flags on `rootCmd`, local flags on `xxxCmd`)
- `main.go` always sets up a `slog.Logger` (JSON handler, debug level, with source) and stores it in context via `contextkey.WithSlogLogger`
