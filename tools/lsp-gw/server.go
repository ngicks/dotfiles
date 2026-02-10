package main

import (
	"crypto/sha256"
	"fmt"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"time"
)

// SocketDir returns the base directory for lsp-gw sockets.
func SocketDir() string {
	dir := os.Getenv("XDG_RUNTIME_DIR")
	if dir == "" {
		dir = "/tmp"
	}
	return filepath.Join(dir, "lsp-gw")
}

// ProjectSocket computes the socket path for a given project root.
func ProjectSocket(projectRoot string) string {
	h := sha256.Sum256([]byte(projectRoot))
	return filepath.Join(SocketDir(), fmt.Sprintf("%x.sock", h))
}

// DetectProjectRoot uses git to find the project root, falling back to cwd.
func DetectProjectRoot() (string, error) {
	out, err := exec.Command("git", "rev-parse", "--show-toplevel").Output()
	if err == nil {
		return strings.TrimSpace(string(out)), nil
	}
	return os.Getwd()
}

// IsServerRunning checks if a Neovim server is accepting connections on the socket.
func IsServerRunning(socket string) bool {
	conn, err := net.DialTimeout("unix", socket, 1*time.Second)
	if err != nil {
		return false
	}
	conn.Close()
	return true
}

// StartServer spawns a headless Neovim instance listening on the given socket.
func StartServer(socket, projectRoot string) error {
	// Ensure socket directory exists
	if err := os.MkdirAll(filepath.Dir(socket), 0700); err != nil {
		return fmt.Errorf("mkdir socket dir: %w", err)
	}

	// Check if already running
	if IsServerRunning(socket) {
		return nil
	}

	// Remove stale socket file
	if _, err := os.Stat(socket); err == nil {
		os.Remove(socket)
	}

	cmd := exec.Command("nvim", "--headless", "--listen", socket)
	cmd.Dir = projectRoot
	cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true}
	cmd.Stdout = nil
	cmd.Stderr = nil

	if err := cmd.Start(); err != nil {
		return fmt.Errorf("start nvim: %w", err)
	}

	// Release the process so it outlives us
	if err := cmd.Process.Release(); err != nil {
		return fmt.Errorf("release nvim process: %w", err)
	}

	// Wait for server readiness via RPC handshake
	for i := 0; i < 50; i++ {
		time.Sleep(200 * time.Millisecond)
		client, err := Connect(socket)
		if err != nil {
			continue
		}
		var result int
		if err := client.ExecLua("return 1", &result); err == nil {
			client.Close()
			return nil
		}
		client.Close()
	}

	return fmt.Errorf("server did not become ready within 10s")
}

// StopServer sends qa! to the Neovim server and cleans up.
func StopServer(socket string) error {
	if !IsServerRunning(socket) {
		// Clean up stale socket if exists
		os.Remove(socket)
		return nil
	}

	client, err := Connect(socket)
	if err != nil {
		os.Remove(socket)
		return nil
	}

	// Send quit command (ignore error since connection closes)
	_ = client.Command("qa!")
	client.Close()

	// Wait for socket to disappear
	for i := 0; i < 15; i++ {
		time.Sleep(200 * time.Millisecond)
		if !IsServerRunning(socket) {
			break
		}
	}

	os.Remove(socket)
	return nil
}

// ServerStatus returns a map describing the server state.
func ServerStatus(socket string) map[string]interface{} {
	result := map[string]interface{}{
		"socket":  socket,
		"running": false,
	}

	if IsServerRunning(socket) {
		result["running"] = true
	}

	return result
}

// EnsureRunning starts the server if it's not already running.
func EnsureRunning(socket, projectRoot string) error {
	if IsServerRunning(socket) {
		return nil
	}
	fmt.Fprintf(os.Stderr, "starting server for %s...\n", projectRoot)
	return StartServer(socket, projectRoot)
}
