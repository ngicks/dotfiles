package cmd

import (
	"fmt"
	"strconv"

	"github.com/spf13/cobra"
	pb "github.com/watage/lsp-gw/proto"
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

			resp, rpcErr := client.GetHover(cmd.Context(), &pb.LocationRequest{
				Project:  project,
				Filepath: filepath,
				Line:     int32(line),
				Col:      int32(col),
			})
			outputQueryResponse(resp, rpcErr)
			return nil
		},
	}
}
