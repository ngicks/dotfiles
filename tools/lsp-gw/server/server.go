package server

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

	"github.com/watage/lsp-gw/gateway"
)

// SocketDir returns the base directory for lsp-gw sockets.
func SocketDir() string {
	dir := os.Getenv("XDG_RUNTIME_DIR")
	if dir == "" {
		dir = "/tmp"
	}
	return filepath.Join(dir, "lsp-gw")
}

// DaemonSocket returns the fixed socket path for the daemon.
func DaemonSocket() string {
	return filepath.Join(SocketDir(), "daemon.sock")
}

// NvimSocketPath computes the neovim socket path for a given project root.
func NvimSocketPath(projectRoot string) string {
	h := sha256.Sum256([]byte(projectRoot))
	return filepath.Join(SocketDir(), fmt.Sprintf("%x.nvim.sock", h))
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

// StartNeovim spawns a headless Neovim instance listening on the given socket.
// The caller is responsible for preparing the Lua runtime (luaDir) beforehand.
// singleflight in the daemon prevents concurrent starts for the same project.
func StartNeovim(nvimSocket, projectRoot, luaDir string) error {
	if err := os.MkdirAll(filepath.Dir(nvimSocket), 0o700); err != nil {
		return fmt.Errorf("mkdir socket dir: %w", err)
	}

	// Remove stale socket file
	if _, err := os.Stat(nvimSocket); err == nil {
		os.Remove(nvimSocket)
	}

	// Pin the embedded lsp_gateway module via package.preload so require()
	// always loads it regardless of RTP or user config caching.
	luaFile := filepath.Join(luaDir, "lua", "lsp_gateway", "init.lua")
	preloadCmd := fmt.Sprintf(
		"lua package.preload['lsp_gateway'] = loadfile('%s')",
		luaFile,
	)

	cmd := exec.Command("nvim", "--headless", "--listen", nvimSocket,
		"--cmd", preloadCmd)
	cmd.Dir = projectRoot
	cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true}
	cmd.Stdout = nil
	cmd.Stderr = nil

	if err := cmd.Start(); err != nil {
		return fmt.Errorf("start nvim: %w", err)
	}

	if err := cmd.Process.Release(); err != nil {
		return fmt.Errorf("release nvim process: %w", err)
	}

	// Wait for server readiness via RPC handshake
	for range 50 {
		time.Sleep(200 * time.Millisecond)
		client, err := gateway.Connect(nvimSocket)
		if err != nil {
			continue
		}
		var result int
		if err := client.ExecLua("require('lsp_gateway'); return 1", &result); err == nil {
			client.Close()
			return nil
		}
		client.Close()
	}

	return fmt.Errorf("server did not become ready within 10s")
}

// StopNeovim sends qa! to the Neovim server and removes the socket file.
func StopNeovim(nvimSocket string) error {
	if !IsServerRunning(nvimSocket) {
		os.Remove(nvimSocket)
		return nil
	}

	client, err := gateway.Connect(nvimSocket)
	if err != nil {
		os.Remove(nvimSocket)
		return nil
	}

	_ = client.Command("qa!")
	client.Close()

	for range 15 {
		time.Sleep(200 * time.Millisecond)
		if !IsServerRunning(nvimSocket) {
			break
		}
	}

	os.Remove(nvimSocket)
	return nil
}
