package cmd

import (
	"bufio"
	"fmt"
	"log"
	"os"

	"github.com/spf13/cobra"
	"github.com/watage/lsp-gw/gateway"
	"github.com/watage/lsp-gw/lsp"
	"github.com/watage/lsp-gw/server"
)

func newLspCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "lsp",
		Short: "Run as stdio LSP server",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			// stdout is the LSP protocol channel; redirect logs to stderr.
			log.SetOutput(os.Stderr)

			project, err := resolveProject()
			if err != nil {
				return fmt.Errorf("resolve project: %w", err)
			}

			luaDir, err := server.PrepareLuaRuntime()
			if err != nil {
				return fmt.Errorf("prepare lua runtime: %w", err)
			}
			defer server.CleanupLuaRuntime(luaDir)

			nvimSocket := server.NvimSocketPath(project)
			if err := server.StartNeovim(nvimSocket, project, luaDir); err != nil {
				return fmt.Errorf("start neovim: %w", err)
			}
			defer server.StopNeovim(nvimSocket)

			nvimClient, err := gateway.Connect(nvimSocket)
			if err != nil {
				return fmt.Errorf("connect to neovim: %w", err)
			}
			defer nvimClient.Close()

			handler := lsp.NewHandler(nvimClient, project)
			srv := lsp.NewServer(handler, bufio.NewReader(os.Stdin), os.Stdout)
			return srv.Run(cmd.Context())
		},
	}
}
