package server

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestSocketDir(t *testing.T) {
	t.Run("with XDG_RUNTIME_DIR", func(t *testing.T) {
		t.Setenv("XDG_RUNTIME_DIR", "/run/user/1000")
		got := SocketDir()
		want := "/run/user/1000/lsp-gw"
		if got != want {
			t.Errorf("SocketDir() = %q, want %q", got, want)
		}
	})

	t.Run("without XDG_RUNTIME_DIR", func(t *testing.T) {
		t.Setenv("XDG_RUNTIME_DIR", "")
		got := SocketDir()
		want := "/tmp/lsp-gw"
		if got != want {
			t.Errorf("SocketDir() = %q, want %q", got, want)
		}
	})
}

func TestDaemonSocket(t *testing.T) {
	t.Setenv("XDG_RUNTIME_DIR", "/run/user/1000")
	got := DaemonSocket()
	want := "/run/user/1000/lsp-gw/daemon.sock"
	if got != want {
		t.Errorf("DaemonSocket() = %q, want %q", got, want)
	}
}

func TestNvimSocketPath(t *testing.T) {
	t.Setenv("XDG_RUNTIME_DIR", "/run/user/1000")

	t.Run("deterministic", func(t *testing.T) {
		a := NvimSocketPath("/home/user/project")
		b := NvimSocketPath("/home/user/project")
		if a != b {
			t.Errorf("same input produced different sockets: %q vs %q", a, b)
		}
	})

	t.Run("different input different hash", func(t *testing.T) {
		a := NvimSocketPath("/home/user/project-a")
		b := NvimSocketPath("/home/user/project-b")
		if a == b {
			t.Errorf("different inputs produced same socket: %q", a)
		}
	})

	t.Run("path contains socket dir", func(t *testing.T) {
		sock := NvimSocketPath("/home/user/project")
		dir := SocketDir()
		if !strings.HasPrefix(sock, dir+"/") {
			t.Errorf("socket %q does not start with %q", sock, dir)
		}
	})

	t.Run("ends with .nvim.sock", func(t *testing.T) {
		sock := NvimSocketPath("/home/user/project")
		if !strings.HasSuffix(sock, ".nvim.sock") {
			t.Errorf("socket %q does not end with .nvim.sock", sock)
		}
	})
}

func TestPrepareLuaRuntime(t *testing.T) {
	luaDir, err := PrepareLuaRuntime()
	if err != nil {
		t.Fatalf("PrepareLuaRuntime() error: %v", err)
	}
	defer CleanupLuaRuntime(luaDir)

	initLua := filepath.Join(luaDir, "lua", "lsp_gateway", "init.lua")
	info, err := os.Stat(initLua)
	if err != nil {
		t.Fatalf("init.lua not found: %v", err)
	}
	if info.Size() == 0 {
		t.Error("init.lua is empty")
	}
}

func TestCleanupLuaRuntime(t *testing.T) {
	luaDir, err := PrepareLuaRuntime()
	if err != nil {
		t.Fatalf("PrepareLuaRuntime() error: %v", err)
	}

	CleanupLuaRuntime(luaDir)

	if _, err := os.Stat(luaDir); !os.IsNotExist(err) {
		t.Errorf("directory %q still exists after cleanup", luaDir)
	}
}

func TestCleanupLuaRuntimeEmpty(t *testing.T) {
	// Should not panic with empty string.
	CleanupLuaRuntime("")
}
