package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
	"github.com/watage/lsp-gw/gateway"
)

func newHealthCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "health",
		Short: "Check server health",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			socket, projectRoot, err := resolveSocketAndProject()
			if err != nil {
				outputError(fmt.Sprintf("resolve: %v", err))
				return nil
			}

			runQuery(socket, projectRoot, gateway.LuaHealth)
			return nil
		},
	}
}
