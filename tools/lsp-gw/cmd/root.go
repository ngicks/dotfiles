package cmd

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"github.com/watage/lsp-gw/gateway"
	"github.com/watage/lsp-gw/server"
)

var (
	socketFlag  string
	projectFlag string
	maxIdleFlag int
)

// NewRootCmd creates the root cobra command.
func NewRootCmd() *cobra.Command {
	rootCmd := &cobra.Command{
		Use:           "lsp-gw",
		Short:         "neovim-as-lsp-gateway app.",
		SilenceUsage:  true,
		SilenceErrors: true,
	}

	rootCmd.PersistentFlags().StringVar(&socketFlag, "socket", "", "Neovim socket path")
	rootCmd.PersistentFlags().StringVar(&projectFlag, "project", "", "Project root directory")
	rootCmd.PersistentFlags().IntVar(&maxIdleFlag, "max-idle", 30, "Auto-shutdown after N minutes of inactivity (0 to disable)")

	rootCmd.AddCommand(
		newServerCmd(),
		newDefinitionCmd(),
		newReferencesCmd(),
		newHoverCmd(),
		newSymbolsCmd(),
		newDiagnosticsCmd(),
		newHealthCmd(),
	)

	return rootCmd
}

// resolveSocketAndProject resolves the socket and project root from flags/env/detection.
func resolveSocketAndProject() (string, string, error) {
	projectRoot := projectFlag
	if projectRoot == "" {
		var err error
		projectRoot, err = server.DetectProjectRoot()
		if err != nil {
			return "", "", fmt.Errorf("detect project root: %w", err)
		}
	}

	socket := socketFlag
	if socket == "" {
		socket = os.Getenv("LSP_GW_SOCKET")
	}
	if socket == "" {
		socket = server.ProjectSocket(projectRoot)
	}

	return socket, projectRoot, nil
}

// outputJSON writes a JSON value to stdout.
func outputJSON(v any) {
	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "  ")
	enc.Encode(v)
}

// outputError writes a JSON error to stdout.
func outputError(msg string) {
	outputJSON(map[string]any{
		"ok":    false,
		"error": msg,
	})
}

// runQuery ensures the server is running, connects, and executes a Lua query.
func runQuery(socket, projectRoot, luaCode string, luaArgs ...any) {
	if err := server.EnsureRunning(socket, projectRoot, maxIdleFlag); err != nil {
		outputError(fmt.Sprintf("ensure server: %v", err))
		return
	}

	client, err := gateway.Connect(socket)
	if err != nil {
		outputError(fmt.Sprintf("connect: %v", err))
		return
	}
	defer client.Close()

	result, err := gateway.QueryGateway(client, luaCode, luaArgs...)
	if err != nil {
		outputError(fmt.Sprintf("query: %v", err))
		return
	}

	outputJSON(result)
}
