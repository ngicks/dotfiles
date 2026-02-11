package gateway

import (
	"context"
	"fmt"
	"net"
	"time"

	"github.com/neovim/go-client/nvim"
)

// Lua code strings for ExecLua calls.
const (
	LuaGetDefinition      = `return require('lsp_gateway').get_definition(...)`
	LuaGetReferences      = `return require('lsp_gateway').get_references(...)`
	LuaGetHover           = `return require('lsp_gateway').get_hover(...)`
	LuaGetDocumentSymbols = `return require('lsp_gateway').get_document_symbols(...)`
	LuaGetDiagnostics     = `return require('lsp_gateway').get_diagnostics(...)`
	LuaHealth             = `return require('lsp_gateway').health()`
)

// Connect dials the Neovim Unix socket and returns an *nvim.Nvim client.
func Connect(socket string) (*nvim.Nvim, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	client, err := nvim.Dial(socket,
		nvim.DialContext(ctx),
		nvim.DialNetDial(func(ctx context.Context, network, address string) (net.Conn, error) {
			var d net.Dialer
			return d.DialContext(ctx, "unix", address)
		}),
	)
	if err != nil {
		return nil, fmt.Errorf("dial %s: %w", socket, err)
	}
	return client, nil
}

// QueryGateway executes a Lua snippet via ExecLua and returns the decoded result.
func QueryGateway(client *nvim.Nvim, luaCode string, args ...any) (any, error) {
	var result any
	err := client.ExecLua(luaCode, &result, args...)
	if err != nil {
		return nil, fmt.Errorf("exec lua: %w", err)
	}
	return NormalizeResult(result), nil
}

// NormalizeResult recursively converts map[interface{}]interface{} (from msgpack)
// to map[string]interface{} for JSON serialization.
func NormalizeResult(v any) any {
	switch val := v.(type) {
	case map[any]any:
		m := make(map[string]any, len(val))
		for k, v := range val {
			m[fmt.Sprintf("%v", k)] = NormalizeResult(v)
		}
		return m
	case map[string]any:
		m := make(map[string]any, len(val))
		for k, v := range val {
			m[k] = NormalizeResult(v)
		}
		return m
	case []any:
		for i, v := range val {
			val[i] = NormalizeResult(v)
		}
		return val
	default:
		return v
	}
}
