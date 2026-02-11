package server

import (
	"embed"
	"fmt"
	"os"
)

//go:embed lua/lsp_gateway/init.lua
var luaFS embed.FS

// PrepareLuaRuntime extracts the embedded Lua files to a temp directory.
func PrepareLuaRuntime() (string, error) {
	dir, err := os.MkdirTemp("", "lsp-gw-lua-*")
	if err != nil {
		return "", fmt.Errorf("mkdtemp: %w", err)
	}

	if err := os.CopyFS(dir, luaFS); err != nil {
		os.RemoveAll(dir)
		return "", fmt.Errorf("copy embedded lua: %w", err)
	}

	return dir, nil
}

// CleanupLuaRuntime removes the temp directory created by PrepareLuaRuntime.
func CleanupLuaRuntime(luaDir string) {
	if luaDir != "" {
		os.RemoveAll(luaDir)
	}
}
