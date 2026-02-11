package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
	pb "github.com/watage/lsp-gw/proto"
)

func newDiagnosticsCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "diagnostics <filepath>",
		Short: "Show file diagnostics",
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

			resp, rpcErr := client.GetDiagnostics(cmd.Context(), &pb.FileRequest{
				Project:  project,
				Filepath: args[0],
			})
			outputQueryResponse(resp, rpcErr)
			return nil
		},
	}
}
