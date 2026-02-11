//go:build integration

package main

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
	"time"

	pb "github.com/watage/lsp-gw/proto"
	"github.com/watage/lsp-gw/server"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

var testProjectDir string
var daemonSocket string
var daemonCancel context.CancelFunc

const mainGoContent = `package main

import "fmt"

// Greeter holds a greeting name.
type Greeter struct {
	Name string
}

// Hello returns a greeting string.
func (g *Greeter) Hello() string {
	return fmt.Sprintf("Hello, %s!", g.Name)
}

func main() {
	g := &Greeter{Name: "World"}
	fmt.Println(g.Hello())
}
`

func TestMain(m *testing.M) {
	// Create temp project directory
	tmpDir, err := os.MkdirTemp("", "lsp-gw-integration-*")
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to create temp dir: %v\n", err)
		os.Exit(1)
	}
	testProjectDir = tmpDir
	defer os.RemoveAll(tmpDir)

	// Write go.mod
	goMod := "module example.com/testproject\n\ngo 1.23\n"
	if err := os.WriteFile(filepath.Join(tmpDir, "go.mod"), []byte(goMod), 0o644); err != nil {
		fmt.Fprintf(os.Stderr, "failed to write go.mod: %v\n", err)
		os.Exit(1)
	}

	// Write main.go
	if err := os.WriteFile(filepath.Join(tmpDir, "main.go"), []byte(mainGoContent), 0o644); err != nil {
		fmt.Fprintf(os.Stderr, "failed to write main.go: %v\n", err)
		os.Exit(1)
	}

	// Run go mod tidy
	cmd := exec.Command("go", "mod", "tidy")
	cmd.Dir = tmpDir
	if out, err := cmd.CombinedOutput(); err != nil {
		fmt.Fprintf(os.Stderr, "go mod tidy failed: %v\n%s\n", err, out)
		os.Exit(1)
	}

	// Start daemon
	daemonSocket = filepath.Join(tmpDir, "daemon.sock")
	daemon := server.NewDaemon(daemonSocket, 5)

	ctx, cancel := context.WithCancel(context.Background())
	daemonCancel = cancel

	daemonReady := make(chan error, 1)
	go func() {
		// Signal ready once the socket exists
		go func() {
			for range 100 {
				time.Sleep(100 * time.Millisecond)
				if _, err := os.Stat(daemonSocket); err == nil {
					daemonReady <- nil
					return
				}
			}
			daemonReady <- fmt.Errorf("daemon socket did not appear within 10s")
		}()
		if err := daemon.Run(ctx); err != nil {
			select {
			case daemonReady <- fmt.Errorf("daemon.Run: %w", err):
			default:
			}
		}
	}()

	if err := <-daemonReady; err != nil {
		fmt.Fprintf(os.Stderr, "daemon failed to start: %v\n", err)
		cancel()
		os.Exit(1)
	}

	// Wait for LSP to be ready via gRPC health check
	if err := waitForLSP(daemonSocket, testProjectDir, 60*time.Second); err != nil {
		fmt.Fprintf(os.Stderr, "LSP did not attach: %v\n", err)
		cancel()
		os.Exit(1)
	}

	// Wait for gopls to finish indexing — poll symbols until non-empty
	if err := waitForIndex(daemonSocket, testProjectDir, 30*time.Second); err != nil {
		fmt.Fprintf(os.Stderr, "gopls did not finish indexing: %v\n", err)
		cancel()
		os.Exit(1)
	}

	code := m.Run()

	cancel()
	// Give daemon a moment to shut down
	time.Sleep(500 * time.Millisecond)
	os.Exit(code)
}

func dialTestDaemon(t *testing.T) (pb.LspGatewayClient, func()) {
	t.Helper()
	conn, err := grpc.NewClient(
		"unix:"+daemonSocket,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		t.Fatalf("dial daemon: %v", err)
	}
	return pb.NewLspGatewayClient(conn), func() { conn.Close() }
}

func waitForLSP(socket, projectDir string, timeout time.Duration) error {
	deadline := time.Now().Add(timeout)
	var lastErr error

	conn, err := grpc.NewClient(
		"unix:"+socket,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		return fmt.Errorf("dial daemon: %w", err)
	}
	defer conn.Close()
	client := pb.NewLspGatewayClient(conn)

	for time.Now().Before(deadline) {
		// Trigger file open to make LSP attach
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		_, _ = client.GetDiagnostics(ctx, &pb.FileRequest{Project: projectDir, Filepath: "main.go"})
		cancel()

		ctx2, cancel2 := context.WithTimeout(context.Background(), 5*time.Second)
		resp, err := client.Health(ctx2, &pb.ProjectRequest{Project: projectDir})
		cancel2()
		if err != nil {
			lastErr = err
			time.Sleep(1 * time.Second)
			continue
		}

		if resp.Ok && resp.Result != nil {
			s := resp.Result.GetStructValue()
			if s != nil {
				// Check that an LSP client is actually attached (not just nvim running)
				clients := s.Fields["lsp_clients"]
				if clients != nil {
					list := clients.GetListValue()
					if list != nil && len(list.Values) > 0 {
						return nil
					}
				}
			}
		}

		lastErr = fmt.Errorf("health ok but no LSP client yet: %v", resp)
		time.Sleep(1 * time.Second)
	}
	return fmt.Errorf("timeout waiting for LSP: %v", lastErr)
}

func waitForIndex(socket, projectDir string, timeout time.Duration) error {
	deadline := time.Now().Add(timeout)

	conn, err := grpc.NewClient(
		"unix:"+socket,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		return fmt.Errorf("dial daemon: %w", err)
	}
	defer conn.Close()
	client := pb.NewLspGatewayClient(conn)

	for time.Now().Before(deadline) {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		resp, err := client.GetDocumentSymbols(ctx, &pb.FileRequest{
			Project:  projectDir,
			Filepath: "main.go",
		})
		cancel()
		if err == nil && resp.Ok && resp.Result != nil {
			list := resp.Result.GetListValue()
			if list != nil && len(list.Values) > 0 {
				return nil
			}
		}
		time.Sleep(1 * time.Second)
	}
	return fmt.Errorf("timeout waiting for gopls to index")
}

func TestIntegrationHealth(t *testing.T) {
	client, cleanup := dialTestDaemon(t)
	defer cleanup()

	resp, err := client.Health(context.Background(), &pb.ProjectRequest{Project: testProjectDir})
	if err != nil {
		t.Fatalf("Health RPC failed: %v", err)
	}
	if !resp.Ok {
		t.Fatalf("health ok != true: %v", resp)
	}

	s := resp.Result.GetStructValue()
	if s == nil {
		t.Fatal("result is not a struct")
	}
	pid := s.Fields["pid"]
	if pid == nil || pid.GetNumberValue() <= 0 {
		t.Fatalf("expected positive pid, got: %v", pid)
	}
}

func TestIntegrationDefinition(t *testing.T) {
	client, cleanup := dialTestDaemon(t)
	defer cleanup()

	resp, err := client.GetDefinition(context.Background(), &pb.LocationRequest{
		Project:  testProjectDir,
		Filepath: "main.go",
		Line:     16,
		Col:      17,
	})
	if err != nil {
		t.Fatalf("GetDefinition RPC failed: %v", err)
	}
	if !resp.Ok {
		t.Fatalf("definition ok != true: error=%s", resp.Error)
	}

	results := resp.Result.GetListValue()
	if results == nil || len(results.Values) == 0 {
		t.Fatal("expected at least one definition location")
	}

	first := results.Values[0].GetStructValue()
	if first == nil {
		t.Fatal("first result is not a struct")
	}
	filename := first.Fields["filename"]
	if filename == nil || filename.GetStringValue() == "" {
		t.Errorf("first result missing filename: %v", first)
	}
}

func TestIntegrationReferences(t *testing.T) {
	client, cleanup := dialTestDaemon(t)
	defer cleanup()

	resp, err := client.GetReferences(context.Background(), &pb.LocationRequest{
		Project:  testProjectDir,
		Filepath: "main.go",
		Line:     10,
		Col:      20,
	})
	if err != nil {
		t.Fatalf("GetReferences RPC failed: %v", err)
	}
	if !resp.Ok {
		t.Fatalf("references ok != true: error=%s", resp.Error)
	}

	results := resp.Result.GetListValue()
	if results == nil || len(results.Values) < 2 {
		t.Errorf("expected at least 2 references, got %v", results)
	}
}

func TestIntegrationHover(t *testing.T) {
	client, cleanup := dialTestDaemon(t)
	defer cleanup()

	resp, err := client.GetHover(context.Background(), &pb.LocationRequest{
		Project:  testProjectDir,
		Filepath: "main.go",
		Line:     10,
		Col:      20,
	})
	if err != nil {
		t.Fatalf("GetHover RPC failed: %v", err)
	}
	if !resp.Ok {
		t.Fatalf("hover ok != true: error=%s", resp.Error)
	}

	result := resp.Result.GetStringValue()
	if len(result) == 0 {
		t.Error("hover result is empty")
	}
}

func TestIntegrationSymbols(t *testing.T) {
	client, cleanup := dialTestDaemon(t)
	defer cleanup()

	resp, err := client.GetDocumentSymbols(context.Background(), &pb.FileRequest{
		Project:  testProjectDir,
		Filepath: "main.go",
	})
	if err != nil {
		t.Fatalf("GetDocumentSymbols RPC failed: %v", err)
	}
	if !resp.Ok {
		t.Fatalf("symbols ok != true: error=%s", resp.Error)
	}

	results := resp.Result.GetListValue()
	if results == nil || len(results.Values) == 0 {
		t.Fatal("expected at least one symbol")
	}

	foundGreeter := false
	for _, v := range results.Values {
		s := v.GetStructValue()
		if s == nil {
			continue
		}
		name := s.Fields["name"]
		if name != nil && name.GetStringValue() == "Greeter" {
			foundGreeter = true
			break
		}
	}
	if !foundGreeter {
		t.Errorf("expected to find Greeter symbol, got: %v", results)
	}
}

func TestIntegrationDiagnostics(t *testing.T) {
	client, cleanup := dialTestDaemon(t)
	defer cleanup()

	resp, err := client.GetDiagnostics(context.Background(), &pb.FileRequest{
		Project:  testProjectDir,
		Filepath: "main.go",
	})
	if err != nil {
		t.Fatalf("GetDiagnostics RPC failed: %v", err)
	}
	if !resp.Ok {
		t.Fatalf("diagnostics ok != true: error=%s", resp.Error)
	}
	// result should be a list (may be empty for clean code) or null
}

func TestIntegrationDaemonStatus(t *testing.T) {
	client, cleanup := dialTestDaemon(t)
	defer cleanup()

	resp, err := client.DaemonStatus(context.Background(), &pb.DaemonStatusRequest{})
	if err != nil {
		t.Fatalf("DaemonStatus RPC failed: %v", err)
	}
	if !resp.Ok {
		t.Fatalf("status ok != true: error=%s", resp.Error)
	}

	s := resp.Result.GetStructValue()
	if s == nil {
		t.Fatal("result is not a struct")
	}
	projects := s.Fields["projects"]
	if projects == nil {
		t.Fatal("result missing projects field")
	}
}
