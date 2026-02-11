package cmd

import (
	"testing"

	"github.com/spf13/cobra"
)

func executeCommand(args ...string) error {
	cmd := NewRootCmd()
	cmd.SetArgs(args)
	return cmd.Execute()
}

func TestCommandTree(t *testing.T) {
	root := NewRootCmd()
	want := map[string]bool{
		"server":      false,
		"definition":  false,
		"references":  false,
		"hover":       false,
		"symbols":     false,
		"diagnostics": false,
		"health":      false,
	}

	for _, c := range root.Commands() {
		if _, ok := want[c.Name()]; ok {
			want[c.Name()] = true
		}
	}

	for name, found := range want {
		if !found {
			t.Errorf("subcommand %q not found on root", name)
		}
	}
}

func TestServerSubcommands(t *testing.T) {
	root := NewRootCmd()
	var serverCmd *cobra.Command
	for _, c := range root.Commands() {
		if c.Name() == "server" {
			serverCmd = c
			break
		}
	}
	if serverCmd == nil {
		t.Fatal("server subcommand not found")
	}

	want := map[string]bool{
		"start":  false,
		"stop":   false,
		"status": false,
	}

	for _, c := range serverCmd.Commands() {
		if _, ok := want[c.Name()]; ok {
			want[c.Name()] = true
		}
	}

	for name, found := range want {
		if !found {
			t.Errorf("server subcommand %q not found", name)
		}
	}
}

func TestDefinitionArgs(t *testing.T) {
	if err := executeCommand("definition"); err == nil {
		t.Error("expected error with 0 args")
	}
	if err := executeCommand("definition", "file.go", "1"); err == nil {
		t.Error("expected error with 2 args")
	}
}

func TestReferencesArgs(t *testing.T) {
	if err := executeCommand("references"); err == nil {
		t.Error("expected error with 0 args")
	}
}

func TestHoverArgs(t *testing.T) {
	if err := executeCommand("hover"); err == nil {
		t.Error("expected error with 0 args")
	}
}

func TestSymbolsArgs(t *testing.T) {
	if err := executeCommand("symbols"); err == nil {
		t.Error("expected error with 0 args")
	}
	if err := executeCommand("symbols", "a", "b"); err == nil {
		t.Error("expected error with 2 args")
	}
}

func TestDiagnosticsArgs(t *testing.T) {
	if err := executeCommand("diagnostics"); err == nil {
		t.Error("expected error with 0 args")
	}
}

func TestHealthArgs(t *testing.T) {
	if err := executeCommand("health", "extra"); err == nil {
		t.Error("expected error with 1 arg")
	}
}

func TestServerStartArgs(t *testing.T) {
	if err := executeCommand("server", "start", "extra"); err == nil {
		t.Error("expected error with 1 arg")
	}
}

func TestServerStopArgs(t *testing.T) {
	if err := executeCommand("server", "stop", "extra"); err == nil {
		t.Error("expected error with 1 arg")
	}
}

func TestServerStatusArgs(t *testing.T) {
	if err := executeCommand("server", "status", "extra"); err == nil {
		t.Error("expected error with 1 arg")
	}
}

func TestMaxIdleFlag(t *testing.T) {
	root := NewRootCmd()
	var serverCmd *cobra.Command
	for _, c := range root.Commands() {
		if c.Name() == "server" {
			serverCmd = c
			break
		}
	}
	if serverCmd == nil {
		t.Fatal("server subcommand not found")
	}
	var startCmd *cobra.Command
	for _, c := range serverCmd.Commands() {
		if c.Name() == "start" {
			startCmd = c
			break
		}
	}
	if startCmd == nil {
		t.Fatal("server start subcommand not found")
	}

	f := startCmd.Flags().Lookup("max-idle")
	if f == nil {
		t.Fatal("--max-idle flag not found on server start")
	}
	if f.DefValue != "30" {
		t.Errorf("--max-idle default = %q, want %q", f.DefValue, "30")
	}
}

func TestSocketFlag(t *testing.T) {
	root := NewRootCmd()
	f := root.PersistentFlags().Lookup("socket")
	if f == nil {
		t.Fatal("--socket flag not found")
	}
}

func TestProjectFlag(t *testing.T) {
	root := NewRootCmd()
	f := root.PersistentFlags().Lookup("project")
	if f == nil {
		t.Fatal("--project flag not found")
	}
}
