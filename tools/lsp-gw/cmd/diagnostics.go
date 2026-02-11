package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
	"github.com/watage/lsp-gw/gateway"
)

func newDiagnosticsCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "diagnostics <filepath>",
		Short: "Show file diagnostics",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			socket, projectRoot, err := resolveSocketAndProject()
			if err != nil {
				outputError(fmt.Sprintf("resolve: %v", err))
				return nil
			}

			runQuery(socket, projectRoot, gateway.LuaGetDiagnostics, args[0])
			return nil
		},
	}
}
