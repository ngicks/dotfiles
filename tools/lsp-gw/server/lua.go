package server

import (
	"embed"
	"fmt"
	"os"
	"path/filepath"
)

//go:embed lua/lsp_gateway/init.lua
var luaFS embed.FS

// PrepareLuaRuntime writes the embedded Lua plugin to a temp directory
// and returns the path to prepend to Neovim's runtimepath.
func PrepareLuaRuntime() (string, error) {
	tmpDir, err := os.MkdirTemp("", "lsp-gw-lua-*")
	if err != nil {
		return "", fmt.Errorf("create temp dir: %w", err)
	}

	data, err := luaFS.ReadFile("lua/lsp_gateway/init.lua")
	if err != nil {
		os.RemoveAll(tmpDir)
		return "", fmt.Errorf("read embedded lua: %w", err)
	}

	luaDir := filepath.Join(tmpDir, "lua", "lsp_gateway")
	if err := os.MkdirAll(luaDir, 0755); err != nil {
		os.RemoveAll(tmpDir)
		return "", fmt.Errorf("mkdir lua dir: %w", err)
	}

	if err := os.WriteFile(filepath.Join(luaDir, "init.lua"), data, 0644); err != nil {
		os.RemoveAll(tmpDir)
		return "", fmt.Errorf("write lua file: %w", err)
	}

	return tmpDir, nil
}

// CleanupLuaRuntime removes the temp directory created by PrepareLuaRuntime.
func CleanupLuaRuntime(luaDir string) {
	if luaDir != "" {
		os.RemoveAll(luaDir)
	}
}
