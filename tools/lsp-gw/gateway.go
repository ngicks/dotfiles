package main

import (
	"context"
	"fmt"
	"net"
	"time"

	"github.com/neovim/go-client/nvim"
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
func QueryGateway(client *nvim.Nvim, luaCode string, args ...interface{}) (interface{}, error) {
	var result interface{}
	err := client.ExecLua(luaCode, &result, args...)
	if err != nil {
		return nil, fmt.Errorf("exec lua: %w", err)
	}
	return normalizeResult(result), nil
}

// normalizeResult recursively converts map[interface{}]interface{} (from msgpack)
// to map[string]interface{} for JSON serialization.
func normalizeResult(v interface{}) interface{} {
	switch val := v.(type) {
	case map[interface{}]interface{}:
		m := make(map[string]interface{}, len(val))
		for k, v := range val {
			m[fmt.Sprintf("%v", k)] = normalizeResult(v)
		}
		return m
	case map[string]interface{}:
		m := make(map[string]interface{}, len(val))
		for k, v := range val {
			m[k] = normalizeResult(v)
		}
		return m
	case []interface{}:
		for i, v := range val {
			val[i] = normalizeResult(v)
		}
		return val
	default:
		return v
	}
}
