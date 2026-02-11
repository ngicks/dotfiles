package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
	"github.com/watage/lsp-gw/server"
)

func newServerCmd() *cobra.Command {
	serverCmd := &cobra.Command{
		Use:   "server",
		Short: "Manage the headless Neovim server",
	}

	serverCmd.AddCommand(
		newServerStartCmd(),
		newServerStopCmd(),
		newServerStatusCmd(),
	)

	return serverCmd
}

func newServerStartCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "start",
		Short: "Start the headless Neovim server",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			socket, projectRoot, err := resolveSocketAndProject()
			if err != nil {
				outputError(fmt.Sprintf("resolve: %v", err))
				return nil
			}
			if err := server.StartServer(socket, projectRoot, maxIdleFlag); err != nil {
				outputError(fmt.Sprintf("start server: %v", err))
				return nil
			}
			outputJSON(map[string]any{"ok": true, "result": "server started"})
			return nil
		},
	}
}

func newServerStopCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "stop",
		Short: "Stop the headless Neovim server",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			socket, _, err := resolveSocketAndProject()
			if err != nil {
				outputError(fmt.Sprintf("resolve: %v", err))
				return nil
			}
			if err := server.StopServer(socket); err != nil {
				outputError(fmt.Sprintf("stop server: %v", err))
				return nil
			}
			outputJSON(map[string]any{"ok": true, "result": "server stopped"})
			return nil
		},
	}
}

func newServerStatusCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "status",
		Short: "Show the server status",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			socket, _, err := resolveSocketAndProject()
			if err != nil {
				outputError(fmt.Sprintf("resolve: %v", err))
				return nil
			}
			status := server.ServerStatus(socket)
			outputJSON(map[string]any{"ok": true, "result": status})
			return nil
		},
	}
}
