package lsp

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"sync"
)

// Server is a stdio LSP server that proxies requests to Neovim via msgpack-rpc.
type Server struct {
	handler  *Handler
	reader   *bufio.Reader
	writer   io.Writer
	mu       sync.Mutex // serialize writes to stdout
	shutdown bool
}

// NewServer creates a new LSP stdio server.
func NewServer(handler *Handler, reader *bufio.Reader, writer io.Writer) *Server {
	return &Server{
		handler: handler,
		reader:  reader,
		writer:  writer,
	}
}

// Run reads LSP messages from stdin and dispatches them until exit or context cancellation.
func (s *Server) Run(ctx context.Context) error {
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
		}

		body, err := ReadMessage(s.reader)
		if err != nil {
			if err == io.EOF || err == io.ErrUnexpectedEOF {
				return nil
			}
			return fmt.Errorf("read message: %w", err)
		}

		var req Request
		if err := json.Unmarshal(body, &req); err != nil {
			s.sendError(nil, -32700, "parse error")
			continue
		}

		isRequest := req.ID != nil
		if isRequest {
			s.handleRequest(ctx, &req)
		} else {
			s.handleNotification(&req)
		}
	}
}

func (s *Server) handleRequest(ctx context.Context, req *Request) {
	// Pre-initialize: only allow "initialize".
	if !s.handler.initialized && req.Method != "initialize" {
		s.sendError(req.ID, -32002, "server not initialized")
		return
	}

	switch req.Method {
	case "initialize":
		result, rpcErr := s.handler.handleInitialize(ctx, req.Params)
		s.sendResponse(req.ID, result, rpcErr)

	case "shutdown":
		s.shutdown = true
		s.sendResponse(req.ID, nil, nil)

	case "textDocument/definition":
		result, rpcErr := s.handler.handleDefinition(ctx, req.Params)
		s.sendResponse(req.ID, result, rpcErr)

	case "textDocument/references":
		result, rpcErr := s.handler.handleReferences(ctx, req.Params)
		s.sendResponse(req.ID, result, rpcErr)

	case "textDocument/hover":
		result, rpcErr := s.handler.handleHover(ctx, req.Params)
		s.sendResponse(req.ID, result, rpcErr)

	case "textDocument/documentSymbol":
		result, rpcErr := s.handler.handleDocumentSymbol(ctx, req.Params)
		s.sendResponse(req.ID, result, rpcErr)

	case "textDocument/diagnostic":
		result, rpcErr := s.handler.handleDiagnostic(ctx, req.Params)
		s.sendResponse(req.ID, result, rpcErr)

	default:
		s.sendError(req.ID, -32601, fmt.Sprintf("method not found: %s", req.Method))
	}
}

func (s *Server) handleNotification(req *Request) {
	switch req.Method {
	case "initialized":
		// No-op.
	case "exit":
		if s.shutdown {
			os.Exit(0)
		}
		os.Exit(1)
	case "textDocument/didOpen", "textDocument/didClose", "textDocument/didSave", "textDocument/didChange":
		// No-op: neovim reads from disk.
	case "$/cancelRequest":
		// Ignored: all requests are synchronous.
	default:
		// Unknown notifications are silently ignored per LSP spec.
		log.Printf("ignored notification: %s", req.Method)
	}
}

func (s *Server) sendResponse(id json.RawMessage, result any, rpcErr *ResponseError) {
	resp := Response{
		JSONRPC: "2.0",
		ID:      id,
		Result:  result,
		Error:   rpcErr,
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if err := WriteMessage(s.writer, resp); err != nil {
		log.Printf("write response: %v", err)
	}
}

func (s *Server) sendError(id json.RawMessage, code int, message string) {
	s.sendResponse(id, nil, &ResponseError{Code: code, Message: message})
}
