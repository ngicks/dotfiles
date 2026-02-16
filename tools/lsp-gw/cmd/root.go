package cmd

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/spf13/cobra"
	pb "github.com/watage/lsp-gw/proto"
	"github.com/watage/lsp-gw/server"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/protobuf/encoding/protojson"
)

var (
	socketFlag  string
	projectFlag string
)

// NewRootCmd creates the root cobra command.
func NewRootCmd() *cobra.Command {
	rootCmd := &cobra.Command{
		Use:           "lsp-gw",
		Short:         "neovim-as-lsp-gateway app.",
		SilenceUsage:  true,
		SilenceErrors: true,
		Args:          cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			return cmd.Help()
		},
	}

	rootCmd.PersistentFlags().StringVar(&socketFlag, "socket", "", "Daemon socket path")
	rootCmd.PersistentFlags().StringVar(&projectFlag, "project", "", "Project root directory")

	rootCmd.AddCommand(
		newServerCmd(),
		newDefinitionCmd(),
		newReferencesCmd(),
		newHoverCmd(),
		newSymbolsCmd(),
		newDiagnosticsCmd(),
		newHealthCmd(),
		newLspCmd(),
	)

	return rootCmd
}

// resolveDaemonSocket resolves the daemon socket from flag/env/default.
func resolveDaemonSocket() string {
	if socketFlag != "" {
		return socketFlag
	}
	if s := os.Getenv("LSP_GW_SOCKET"); s != "" {
		return s
	}
	return server.DaemonSocket()
}

// resolveProject resolves the project root from flag or auto-detection.
func resolveProject() (string, error) {
	if projectFlag != "" {
		return projectFlag, nil
	}
	return server.DetectProjectRoot()
}

// dialDaemon connects to the gRPC daemon and returns the connection and client.
func dialDaemon(socket string) (*grpc.ClientConn, pb.LspGatewayClient, error) {
	conn, err := grpc.NewClient(
		"unix:"+socket,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		return nil, nil, fmt.Errorf("dial daemon: %w", err)
	}
	return conn, pb.NewLspGatewayClient(conn), nil
}

// outputJSON writes a JSON value to stdout.
func outputJSON(v any) {
	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "  ")
	enc.Encode(v)
}

// outputError writes a JSON error to stdout.
func outputError(msg string) {
	outputJSON(map[string]any{
		"ok":    false,
		"error": msg,
	})
}

// outputQueryResponse converts a gRPC QueryResponse to JSON and prints it.
func outputQueryResponse(resp *pb.QueryResponse, err error) {
	if err != nil {
		outputError(fmt.Sprintf("rpc: %v", err))
		return
	}

	// Use protojson to marshal, then re-parse to get clean JSON
	raw, err := protojson.Marshal(resp)
	if err != nil {
		outputError(fmt.Sprintf("marshal: %v", err))
		return
	}

	// Re-parse and pretty-print
	var m any
	if err := json.Unmarshal(raw, &m); err != nil {
		os.Stdout.Write(raw)
		os.Stdout.Write([]byte("\n"))
		return
	}
	outputJSON(m)
}
