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

// sidecarPath returns the path of the sidecar file that stores the lua temp dir.
func sidecarPath(socket string) string {
	return socket + ".luadir"
}

// lockfilePath returns the path of the lockfile for the given socket.
func lockfilePath(socket string) string {
	return socket + ".lock"
}

// acquireLock opens/creates the lockfile and acquires an exclusive flock.
// The caller must defer releaseLock on the returned file.
func acquireLock(socket string) (*os.File, error) {
	f, err := os.OpenFile(lockfilePath(socket), os.O_CREATE|os.O_RDWR, 0600)
	if err != nil {
		return nil, fmt.Errorf("open lockfile: %w", err)
	}
	if err := syscall.Flock(int(f.Fd()), syscall.LOCK_EX); err != nil {
		f.Close()
		return nil, fmt.Errorf("flock: %w", err)
	}
	return f, nil
}

// releaseLock releases the flock and closes the file.
func releaseLock(f *os.File) {
	syscall.Flock(int(f.Fd()), syscall.LOCK_UN)
	f.Close()
}

// StartServer spawns a headless Neovim instance listening on the given socket.
// It injects the embedded Lua plugin via runtimepath prepend.
func StartServer(socket, projectRoot string, maxIdleMins int) error {
	// Ensure socket directory exists
	if err := os.MkdirAll(filepath.Dir(socket), 0700); err != nil {
		return fmt.Errorf("mkdir socket dir: %w", err)
	}

	// Acquire lockfile to serialize concurrent startup attempts
	lockFile, err := acquireLock(socket)
	if err != nil {
		return fmt.Errorf("acquire lock: %w", err)
	}
	defer releaseLock(lockFile)

	// Double-check: another caller may have started the server while we waited
	if IsServerRunning(socket) {
		return nil
	}

	// Remove stale socket file
	if _, err := os.Stat(socket); err == nil {
		os.Remove(socket)
	}

	// Prepare embedded Lua runtime
	luaDir, err := PrepareLuaRuntime()
	if err != nil {
		return fmt.Errorf("prepare lua runtime: %w", err)
	}

	// Write sidecar BEFORE launching nvim so cleanup can find it
	if err := os.WriteFile(sidecarPath(socket), []byte(luaDir), 0600); err != nil {
		CleanupLuaRuntime(luaDir)
		return fmt.Errorf("write sidecar: %w", err)
	}

	// Use fnameescape() to handle spaces in tmpdir path
	rtpCmd := fmt.Sprintf("execute 'set rtp^=' . fnameescape('%s')", luaDir)
	idleCmd := fmt.Sprintf("let g:lsp_gw_max_idle_mins=%d", maxIdleMins)
	socketCmd := fmt.Sprintf("let g:lsp_gw_socket='%s'", socket)

	cmd := exec.Command("nvim", "--headless", "--listen", socket,
		"--cmd", idleCmd,
		"--cmd", socketCmd,
		"--cmd", rtpCmd)
	cmd.Dir = projectRoot
	cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true}
	cmd.Stdout = nil
	cmd.Stderr = nil

	if err := cmd.Start(); err != nil {
		CleanupLuaRuntime(luaDir)
		os.Remove(sidecarPath(socket))
		return fmt.Errorf("start nvim: %w", err)
	}

	// Release the process so it outlives us
	if err := cmd.Process.Release(); err != nil {
		CleanupLuaRuntime(luaDir)
		os.Remove(sidecarPath(socket))
		return fmt.Errorf("release nvim process: %w", err)
	}

	// Wait for server readiness via RPC handshake
	for range 50 {
		time.Sleep(200 * time.Millisecond)
		client, err := gateway.Connect(socket)
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

// StopServer sends qa! to the Neovim server and cleans up.
func StopServer(socket string) error {
	// Clean up lua temp dir via sidecar
	defer cleanupSidecar(socket)
	// Clean up lockfile after everything else
	defer os.Remove(lockfilePath(socket))

	// Acquire lock to prevent stop racing with a concurrent start
	lockFile, err := acquireLock(socket)
	if err != nil {
		return fmt.Errorf("acquire lock: %w", err)
	}
	defer releaseLock(lockFile)

	if !IsServerRunning(socket) {
		os.Remove(socket)
		return nil
	}

	client, err := gateway.Connect(socket)
	if err != nil {
		os.Remove(socket)
		return nil
	}

	// Send quit command (ignore error since connection closes)
	_ = client.Command("qa!")
	client.Close()

	// Wait for socket to disappear
	for range 15 {
		time.Sleep(200 * time.Millisecond)
		if !IsServerRunning(socket) {
			break
		}
	}

	os.Remove(socket)
	return nil
}

// cleanupSidecar reads and removes the sidecar file, then cleans up the lua dir.
func cleanupSidecar(socket string) {
	sc := sidecarPath(socket)
	data, err := os.ReadFile(sc)
	if err == nil {
		CleanupLuaRuntime(strings.TrimSpace(string(data)))
	}
	os.Remove(sc)
}

// ServerStatus returns a map describing the server state.
func ServerStatus(socket string) map[string]any {
	result := map[string]any{
		"socket":  socket,
		"running": false,
	}

	if IsServerRunning(socket) {
		result["running"] = true
	}

	return result
}

// EnsureRunning starts the server if it's not already running.
func EnsureRunning(socket, projectRoot string, maxIdleMins int) error {
	if IsServerRunning(socket) {
		return nil
	}
	fmt.Fprintf(os.Stderr, "starting server for %s...\n", projectRoot)
	return StartServer(socket, projectRoot, maxIdleMins)
}
