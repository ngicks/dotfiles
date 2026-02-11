package cmd

import (
	"fmt"
	"strconv"

	"github.com/spf13/cobra"
	"github.com/watage/lsp-gw/gateway"
)

func newHoverCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "hover <filepath> <line> <col>",
		Short: "Show hover information",
		Args:  cobra.ExactArgs(3),
		RunE: func(cmd *cobra.Command, args []string) error {
			filepath := args[0]
			line, err := strconv.Atoi(args[1])
			if err != nil {
				outputError(fmt.Sprintf("invalid line number: %s", args[1]))
				return nil
			}
			col, err := strconv.Atoi(args[2])
			if err != nil {
				outputError(fmt.Sprintf("invalid col number: %s", args[2]))
				return nil
			}

			socket, projectRoot, err := resolveSocketAndProject()
			if err != nil {
				outputError(fmt.Sprintf("resolve: %v", err))
				return nil
			}

			runQuery(socket, projectRoot, gateway.LuaGetHover, filepath, line, col)
			return nil
		},
	}
}
