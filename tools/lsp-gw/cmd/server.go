package cmd

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"github.com/spf13/cobra"
	pb "github.com/watage/lsp-gw/proto"
	"github.com/watage/lsp-gw/server"
)

var maxIdleFlag int

func newServerCmd() *cobra.Command {
	serverCmd := &cobra.Command{
		Use:   "server",
		Short: "Manage the lsp-gw daemon",
	}

	serverCmd.AddCommand(
		newServerStartCmd(),
		newServerStopCmd(),
		newServerStatusCmd(),
	)

	return serverCmd
}

func newServerStartCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "start",
		Short: "Start the lsp-gw daemon (foreground)",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			socket := resolveDaemonSocket()
			daemon := server.NewDaemon(socket, maxIdleFlag)

			ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
			defer stop()

			if err := daemon.Run(ctx); err != nil {
				fmt.Fprintf(os.Stderr, "daemon: %v\n", err)
				return err
			}
			return nil
		},
	}
	cmd.Flags().IntVar(&maxIdleFlag, "max-idle", 30, "Auto-shutdown neovim after N minutes of inactivity (0 to disable)")
	return cmd
}

func newServerStopCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "stop",
		Short: "Stop the lsp-gw daemon",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			socket := resolveDaemonSocket()
			conn, client, err := dialDaemon(socket)
			if err != nil {
				outputError(fmt.Sprintf("connect: %v", err))
				return nil
			}
			defer conn.Close()

			resp, err := client.Shutdown(cmd.Context(), &pb.ShutdownRequest{})
			outputQueryResponse(resp, err)
			return nil
		},
	}
}

func newServerStatusCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "status",
		Short: "Show daemon status",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			socket := resolveDaemonSocket()
			conn, client, err := dialDaemon(socket)
			if err != nil {
				outputError(fmt.Sprintf("connect: %v", err))
				return nil
			}
			defer conn.Close()

			resp, err := client.DaemonStatus(cmd.Context(), &pb.DaemonStatusRequest{})
			outputQueryResponse(resp, err)
			return nil
		},
	}
}
