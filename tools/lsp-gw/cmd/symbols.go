package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
	pb "github.com/watage/lsp-gw/proto"
)

func newSymbolsCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "symbols <filepath>",
		Short: "List document symbols",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			project, err := resolveProject()
			if err != nil {
				outputError(fmt.Sprintf("resolve project: %v", err))
				return nil
			}

			conn, client, err := dialDaemon(resolveDaemonSocket())
			if err != nil {
				outputError(fmt.Sprintf("connect: %v", err))
				return nil
			}
			defer conn.Close()

			resp, rpcErr := client.GetDocumentSymbols(cmd.Context(), &pb.FileRequest{
				Project:  project,
				Filepath: args[0],
			})
			outputQueryResponse(resp, rpcErr)
			return nil
		},
	}
}
