package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
	"github.com/watage/lsp-gw/gateway"
)

func newSymbolsCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "symbols <filepath>",
		Short: "List document symbols",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			socket, projectRoot, err := resolveSocketAndProject()
			if err != nil {
				outputError(fmt.Sprintf("resolve: %v", err))
				return nil
			}

			runQuery(socket, projectRoot, gateway.LuaGetDocumentSymbols, args[0])
			return nil
		},
	}
}
