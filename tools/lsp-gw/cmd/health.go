package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
	pb "github.com/watage/lsp-gw/proto"
)

func newHealthCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "health",
		Short: "Check server health",
		Args:  cobra.NoArgs,
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

			resp, rpcErr := client.Health(cmd.Context(), &pb.ProjectRequest{
				Project: project,
			})
			outputQueryResponse(resp, rpcErr)
			return nil
		},
	}
}
