package lsp

import (
	"context"
	"encoding/json"
	"net/url"

	"github.com/neovim/go-client/nvim"
	"github.com/watage/lsp-gw/gateway"
)

// Handler translates LSP method calls to Neovim Lua calls via msgpack-rpc.
type Handler struct {
	nvim        *nvim.Nvim
	project     string
	initialized bool
}

// NewHandler creates a new Handler.
func NewHandler(nvimClient *nvim.Nvim, project string) *Handler {
	return &Handler{nvim: nvimClient, project: project}
}

// --- Lifecycle ---

func (h *Handler) handleInitialize(ctx context.Context, params json.RawMessage) (any, *ResponseError) {
	h.initialized = true

	// Try to extract rootUri from params.
	var p struct {
		RootURI string `json:"rootUri"`
	}
	if len(params) > 0 {
		_ = json.Unmarshal(params, &p)
	}
	if p.RootURI != "" {
		if u, err := url.Parse(p.RootURI); err == nil && u.Path != "" {
			h.project = u.Path
		}
	}

	return map[string]any{
		"capabilities": map[string]any{
			"positionEncoding": "utf-16",
			"textDocumentSync": map[string]any{
				"openClose": true,
				"change":    0, // None
			},
			"definitionProvider":     true,
			"referencesProvider":     true,
			"hoverProvider":          true,
			"documentSymbolProvider": true,
			"diagnosticProvider": map[string]any{
				"interFileDependencies": false,
				"workspaceDiagnostics":  false,
			},
		},
		"serverInfo": map[string]any{
			"name":    "lsp-gw",
			"version": "0.1.0",
		},
	}, nil
}

// --- Query helpers ---

// textDocumentPositionParams extracts uri, line, col from LSP TextDocumentPositionParams.
type textDocumentPositionParams struct {
	TextDocument struct {
		URI string `json:"uri"`
	} `json:"textDocument"`
	Position struct {
		Line      int `json:"line"`
		Character int `json:"character"`
	} `json:"position"`
}

// textDocumentParams extracts just the uri.
type textDocumentParams struct {
	TextDocument struct {
		URI string `json:"uri"`
	} `json:"textDocument"`
}

func uriToPath(uri string) string {
	u, err := url.Parse(uri)
	if err != nil {
		return uri
	}
	return u.Path
}

func pathToURI(path string) string {
	return "file://" + path
}

// queryLua executes a gateway Lua call and extracts the result.
func (h *Handler) queryLua(luaCode string, args ...any) (any, *ResponseError) {
	raw, err := gateway.QueryGateway(h.nvim, luaCode, args...)
	if err != nil {
		return nil, rpcError(-32603, err.Error())
	}
	m, ok := raw.(map[string]any)
	if !ok {
		return nil, rpcError(-32603, "unexpected result type")
	}
	if okVal, _ := m["ok"].(bool); !okVal {
		errMsg, _ := m["error"].(string)
		return nil, rpcError(-32603, errMsg)
	}
	return m["result"], nil
}

func rpcError(code int, msg string) *ResponseError {
	return &ResponseError{Code: code, Message: msg}
}

// --- Location-based queries (definition, references) ---

func (h *Handler) handleDefinition(ctx context.Context, params json.RawMessage) (any, *ResponseError) {
	return h.handleLocationQuery(params, gateway.LuaGetDefinition)
}

func (h *Handler) handleReferences(ctx context.Context, params json.RawMessage) (any, *ResponseError) {
	return h.handleLocationQuery(params, gateway.LuaGetReferences)
}

func (h *Handler) handleLocationQuery(params json.RawMessage, luaCode string) (any, *ResponseError) {
	var p textDocumentPositionParams
	if err := json.Unmarshal(params, &p); err != nil {
		return nil, rpcError(-32602, "invalid params")
	}

	result, rpcErr := h.queryLua(luaCode,
		uriToPath(p.TextDocument.URI),
		p.Position.Line,
		p.Position.Character,
	)
	if rpcErr != nil {
		return nil, rpcErr
	}

	return toLSPLocations(result), nil
}

// toLSPLocations converts [{filename, line, col}, ...] to LSP Location[].
func toLSPLocations(v any) []map[string]any {
	items, ok := v.([]any)
	if !ok {
		return []map[string]any{}
	}
	locations := make([]map[string]any, 0, len(items))
	for _, item := range items {
		m, ok := item.(map[string]any)
		if !ok {
			continue
		}
		filename, _ := m["filename"].(string)
		line := toInt(m["line"])
		col := toInt(m["col"])

		uri := filename
		// Only convert to file:// URI if it looks like a filesystem path.
		if len(filename) > 0 && filename[0] == '/' {
			uri = pathToURI(filename)
		}

		pos := map[string]any{"line": line, "character": col}
		locations = append(locations, map[string]any{
			"uri":   uri,
			"range": map[string]any{"start": pos, "end": pos},
		})
	}
	return locations
}

// --- Hover ---

func (h *Handler) handleHover(ctx context.Context, params json.RawMessage) (any, *ResponseError) {
	var p textDocumentPositionParams
	if err := json.Unmarshal(params, &p); err != nil {
		return nil, rpcError(-32602, "invalid params")
	}

	result, rpcErr := h.queryLua(gateway.LuaGetHover,
		uriToPath(p.TextDocument.URI),
		p.Position.Line,
		p.Position.Character,
	)
	if rpcErr != nil {
		return nil, rpcErr
	}

	text, _ := result.(string)
	if text == "" {
		return nil, nil
	}
	return map[string]any{
		"contents": map[string]any{
			"kind":  "markdown",
			"value": text,
		},
	}, nil
}

// --- Document Symbols ---

func (h *Handler) handleDocumentSymbol(ctx context.Context, params json.RawMessage) (any, *ResponseError) {
	var p textDocumentParams
	if err := json.Unmarshal(params, &p); err != nil {
		return nil, rpcError(-32602, "invalid params")
	}

	result, rpcErr := h.queryLua(gateway.LuaGetDocumentSymbols,
		uriToPath(p.TextDocument.URI),
	)
	if rpcErr != nil {
		return nil, rpcErr
	}

	return toLSPSymbols(result), nil
}

// toLSPSymbols converts [{name, kind, start_line, end_line}, ...] to LSP DocumentSymbol[].
func toLSPSymbols(v any) []map[string]any {
	items, ok := v.([]any)
	if !ok {
		return []map[string]any{}
	}
	symbols := make([]map[string]any, 0, len(items))
	for _, item := range items {
		m, ok := item.(map[string]any)
		if !ok {
			continue
		}
		name, _ := m["name"].(string)
		kind := toInt(m["kind"])
		startLine := toInt(m["start_line"])
		endLine := toInt(m["end_line"])

		symbols = append(symbols, map[string]any{
			"name": name,
			"kind": kind,
			"range": map[string]any{
				"start": map[string]any{"line": startLine, "character": 0},
				"end":   map[string]any{"line": endLine, "character": 0},
			},
			"selectionRange": map[string]any{
				"start": map[string]any{"line": startLine, "character": 0},
				"end":   map[string]any{"line": startLine, "character": 0},
			},
		})
	}
	return symbols
}

// --- Diagnostics ---

func (h *Handler) handleDiagnostic(ctx context.Context, params json.RawMessage) (any, *ResponseError) {
	var p textDocumentParams
	if err := json.Unmarshal(params, &p); err != nil {
		return nil, rpcError(-32602, "invalid params")
	}

	result, rpcErr := h.queryLua(gateway.LuaGetDiagnostics,
		uriToPath(p.TextDocument.URI),
	)
	if rpcErr != nil {
		return nil, rpcErr
	}

	return map[string]any{
		"kind":  "full",
		"items": toLSPDiagnostics(result),
	}, nil
}

// toLSPDiagnostics converts [{line, col, severity, message, source}, ...] to LSP Diagnostic[].
func toLSPDiagnostics(v any) []map[string]any {
	items, ok := v.([]any)
	if !ok {
		return []map[string]any{}
	}
	diagnostics := make([]map[string]any, 0, len(items))
	for _, item := range items {
		m, ok := item.(map[string]any)
		if !ok {
			continue
		}
		line := toInt(m["line"])
		col := toInt(m["col"])
		severity := toInt(m["severity"])
		message, _ := m["message"].(string)
		source, _ := m["source"].(string)

		pos := map[string]any{"line": line, "character": col}
		d := map[string]any{
			"range":    map[string]any{"start": pos, "end": pos},
			"severity": severity,
			"message":  message,
		}
		if source != "" {
			d["source"] = source
		}
		diagnostics = append(diagnostics, d)
	}
	return diagnostics
}

// --- Helpers ---

// toInt converts a number (float64 from JSON, int64 from msgpack) to int.
func toInt(v any) int {
	switch n := v.(type) {
	case float64:
		return int(n)
	case int:
		return n
	case int64:
		return int(n)
	default:
		return 0
	}
}
