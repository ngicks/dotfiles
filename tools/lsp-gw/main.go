package main

import (
	"context"
	"os/signal"
	"syscall"

	"github.com/watage/lsp-gw/cmd"
)

func main() {
	ctx, stop := signal.NotifyContext(
		context.Background(),
		syscall.SIGINT,
		syscall.SIGTERM,
	)
	defer stop()

	rootCmd := cmd.NewRootCmd()
	rootCmd.ExecuteContext(ctx)
}
